-- Create market_orders table if not exists
CREATE TABLE IF NOT EXISTS public.market_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) NOT NULL,
    item_id TEXT NOT NULL, -- The base item_id (e.g. 'weapon_sword')
    quantity INT NOT NULL CHECK (quantity > 0),
    price INT NOT NULL CHECK (price >= 0),
    region_id INT DEFAULT 1,
    listed_at BIGINT DEFAULT extract(epoch from now())::bigint,
    item_data JSONB DEFAULT '{}'::jsonb, -- Instance specific data (enhancement, stats)
    
    constraint valid_quantity check (quantity > 0)
);

-- Enable RLS
ALTER TABLE public.market_orders ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read orders (Idempotent: Drop first)
DROP POLICY IF EXISTS "Public read market orders" ON public.market_orders;
CREATE POLICY "Public read market orders" ON public.market_orders
    FOR SELECT USING (true);

-- Allow users to manage their own orders
DROP POLICY IF EXISTS "Users manage own orders" ON public.market_orders;
CREATE POLICY "Users manage own orders" ON public.market_orders
    FOR ALL USING (auth.uid() = seller_id);


-- RPC: Place Sell Order
-- Removes item from inventory and creates a market listing
CREATE OR REPLACE FUNCTION place_sell_order(
    p_item_row_id UUID, -- The UUID of the row in inventory
    p_quantity INT,
    p_price INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_item_record RECORD;
    v_item_data JSONB;
BEGIN
    v_user_id := auth.uid();
    
    -- 1. Verify item ownership and quantity
    SELECT * INTO v_item_record
    FROM public.inventory
    WHERE row_id = p_item_row_id AND user_id = v_user_id;
    
    IF v_item_record IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;
    
    IF v_item_record.quantity < p_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not enough quantity');
    END IF;

    IF v_item_record.is_equipped = TRUE THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot sell equipped item');
    END IF;

    -- 2. Prepare Item Data (Snapshot stats, enhancement, etc.)
    -- Note: inventory table uses enhancement_level, not upgrade_level
    v_item_data := jsonb_build_object(
        'enhancement_level', v_item_record.enhancement_level, 
        'obtained_at', v_item_record.obtained_at
    );

    -- 3. Create Market Order
    INSERT INTO public.market_orders (
        seller_id, item_id, quantity, price, item_data
    ) VALUES (
        v_user_id, v_item_record.item_id, p_quantity, p_price, v_item_data
    );

    -- 4. Update Inventory
    IF v_item_record.quantity = p_quantity THEN
        -- Sold all -> Delete row
        DELETE FROM public.inventory WHERE row_id = p_item_row_id;
    ELSE
        -- Sold partial -> Decrease quantity
        UPDATE public.inventory 
        SET quantity = quantity - p_quantity 
        WHERE row_id = p_item_row_id;
    END IF;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- RPC: Cancel Sell Order
-- Restores item to inventory if space exists
CREATE OR REPLACE FUNCTION cancel_sell_order(
    p_order_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_order_record RECORD;
    v_slot INT;
BEGIN
    v_user_id := auth.uid();
    
    -- 1. Find Order
    SELECT * INTO v_order_record
    FROM public.market_orders
    WHERE id = p_order_id AND seller_id = v_user_id;
    
    IF v_order_record IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Order not found');
    END IF;
    
    -- 2. Check Inventory Space using Helper
    -- We'll assume the helper handles finding a slot
    -- If we support stacking on return (optional for v1), we'd check that here.
    
    v_slot := public._find_first_empty_slot(v_user_id);
    
    IF v_slot IS NULL THEN
         RETURN jsonb_build_object('success', false, 'error', 'Inventory full');
    END IF;

    -- 3. Restore Item
    INSERT INTO public.inventory (
       user_id, item_id, quantity, slot_position, 
       enhancement_level, obtained_at, is_equipped, row_id
    ) VALUES (
       v_user_id, 
       v_order_record.item_id, 
       v_order_record.quantity, 
       v_slot, 
       (v_order_record.item_data->>'enhancement_level')::int,
       (v_order_record.item_data->>'obtained_at')::bigint,
       FALSE,
       gen_random_uuid()
    );

    -- 4. Delete Order
    DELETE FROM public.market_orders WHERE id = p_order_id;
    
    RETURN jsonb_build_object('success', true);
END;
$$;
