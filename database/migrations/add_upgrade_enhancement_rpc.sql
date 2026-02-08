-- Create upgrade_item_enhancement RPC to safely update item levels bypassing RLS
-- Run this in your Supabase SQL Editor

CREATE OR REPLACE FUNCTION public.upgrade_item_enhancement(p_new_level INT, p_row_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_affected_rows INT;
BEGIN
    UPDATE public.inventory
    SET enhancement_level = p_new_level,
        updated_at = NOW()
    WHERE row_id = p_row_id;

    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;

    IF v_affected_rows > 0 THEN
        RETURN json_build_object('success', true, 'new_level', p_new_level);
    ELSE
        RETURN json_build_object('success', false, 'error', 'Item not found or permission denied');
    END IF;
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;
