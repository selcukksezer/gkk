-- Equipment System Database Schema
-- Adds equipment functionality to inventory table

-- Add equipment columns to inventory table
ALTER TABLE public.inventory 
ADD COLUMN IF NOT EXISTS is_equipped BOOLEAN DEFAULT false;

ALTER TABLE public.inventory
ADD COLUMN IF NOT EXISTS equip_slot TEXT;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_inventory_equipped 
ON public.inventory(user_id, is_equipped) 
WHERE is_equipped = true;

-- RPC Function: Equip Item
CREATE OR REPLACE FUNCTION public.equip_item(
    item_instance_id UUID,
    slot TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_item_row RECORD;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;
    
    -- Get item and verify ownership
    SELECT * INTO v_item_row
    FROM public.inventory
    WHERE row_id = item_instance_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RETURN '{"success": false, "error": "Item not found or not owned by player"}'::jsonb;
    END IF;
    
    -- Unequip any item currently in this slot
    UPDATE public.inventory
    SET is_equipped = FALSE, equip_slot = NULL, updated_at = NOW()
    WHERE user_id = v_user_id 
      AND equip_slot = slot 
      AND is_equipped = TRUE
      AND row_id != item_instance_id;
    
    -- Equip new item
    UPDATE public.inventory
    SET is_equipped = TRUE, equip_slot = slot, updated_at = NOW()
    WHERE row_id = item_instance_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'item_id', item_instance_id,
        'slot', slot
    );
END;
$$;

-- RPC Function: Unequip Item
CREATE OR REPLACE FUNCTION public.unequip_item(
    item_instance_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_updated_count INT;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;
    
    -- Unequip item
    UPDATE public.inventory
    SET is_equipped = FALSE, equip_slot = NULL, updated_at = NOW()
    WHERE row_id = item_instance_id 
      AND user_id = v_user_id
      AND is_equipped = TRUE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    IF v_updated_count = 0 THEN
        RETURN '{"success": false, "error": "Item not found, not owned, or not equipped"}'::jsonb;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'item_id', item_instance_id
    );
END;
$$;

-- RPC Function: Get Equipped Items
CREATE OR REPLACE FUNCTION public.get_equipped_items()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_equipped_items JSONB;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;
    
    -- Fetch equipped items with definitions from items table
    SELECT jsonb_agg(
        jsonb_build_object(
            'row_id', inv.row_id,
            'item_id', inv.item_id,
            'equip_slot', inv.equip_slot,
            'enhancement_level', COALESCE(inv.enhancement_level, 0),
            'quantity', inv.quantity,
            'obtained_at', inv.obtained_at,
            -- Item definition from items table
            'name', it.name,
            'description', it.description,
            'icon', it.icon,
            'item_type', it.type,
            'rarity', it.rarity,
            'attack', it.attack,
            'defense', it.defense,
            'health', it.health,
            'power', it.power,
            'required_level', COALESCE(it.required_level, 1),
            'required_class', it.required_class
        )
    )
    INTO v_equipped_items
    FROM public.inventory inv
    LEFT JOIN public.items it ON inv.item_id = it.id
    WHERE inv.user_id = v_user_id AND inv.is_equipped = TRUE;
    
    -- Return empty array if no items
    IF v_equipped_items IS NULL THEN
        v_equipped_items := '[]'::jsonb;
    END IF;
    
    RETURN jsonb_build_object('success', true, 'items', v_equipped_items);
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.equip_item TO authenticated;
GRANT EXECUTE ON FUNCTION public.unequip_item TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_equipped_items TO authenticated;
