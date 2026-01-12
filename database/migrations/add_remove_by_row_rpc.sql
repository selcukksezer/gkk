-- RPC to remove quantity from a specific inventory row (by row_id)
-- This ensures we delete/sell the exact item instance the user selected, even if duplicates exist.

CREATE OR REPLACE FUNCTION public.remove_inventory_item_by_row(
    p_row_id uuid,
    p_quantity int
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid;
    v_current_quantity int;
    v_item_id text;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Check if row exists and belongs to user
    SELECT quantity, item_id INTO v_current_quantity, v_item_id
    FROM public.inventory
    WHERE row_id = p_row_id AND user_id = v_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    IF p_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Quantity must be positive');
    END IF;

    IF p_quantity > v_current_quantity THEN
         RETURN jsonb_build_object('success', false, 'error', format('Not enough quantity (have: %s, trying to remove: %s)', v_current_quantity, p_quantity));
    END IF;

    -- Update or Delete
    IF p_quantity >= v_current_quantity THEN
        -- Remove completely
        DELETE FROM public.inventory
        WHERE row_id = p_row_id AND user_id = v_user_id;
    ELSE
        -- Update quantity
        UPDATE public.inventory
        SET quantity = quantity - p_quantity,
            updated_at = NOW()
        WHERE row_id = p_row_id AND user_id = v_user_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'removed_item_id', v_item_id,
        'remaining_quantity', GREATEST(0, v_current_quantity - p_quantity)
    );
END;
$$;
