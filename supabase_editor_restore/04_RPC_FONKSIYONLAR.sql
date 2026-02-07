-- ============================================================
-- SUPABASE SQL EDİTÖR - VERİTABANI KURTARMA
-- ============================================================
-- DOSYA 4/5: RPC FONKSİYONLAR
-- ============================================================
--
-- Bu dosya gelişmiş oyun mekaniği fonksiyonlarını ekler:
-- ✓ Kaynak toplama RPC'leri
-- ✓ Oyuncu tesisleri RPC'leri
-- ✓ Tesis tarifleri RPC'leri
-- ✓ Tesis yükseltme RPC'leri
-- ✓ Satın alma RPC'leri
--
-- TALİMATLAR:
-- 1. Bu dosyanın tüm içeriğini kopyalayın
-- 2. Supabase SQL Editor'e yapıştırın
-- 3. RUN butonuna basın
-- 4. İşlem tamamlanana kadar bekleyin (~25 saniye)
-- 5. Sonra 05_VERI_VE_ICERIK.sql dosyasına geçin
--
-- BEKLENEN SÜRE: ~25 saniye
-- BEKLENEN SONUÇ: 6+ RPC fonksiyonu eklendi
-- ============================================================

CREATE OR REPLACE FUNCTION collect_facility_production(p_facility_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_now BIGINT;
    v_job RECORD;
    v_recipe RECORD;
    v_facility RECORD;
    v_existing_inv RECORD;
    v_collected_items JSONB := '[]'::jsonb;
    v_count INT := 0;
    v_prison_time TIMESTAMPTZ;
BEGIN
    v_user_id := auth.uid();
    v_now := EXTRACT(EPOCH FROM NOW())::BIGINT;
    
    -- Facility Check
    SELECT * INTO v_facility FROM public.facilities WHERE id = p_facility_id AND user_id = v_user_id;
    IF v_facility IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Facility not found'); END IF;

    -- PRISON Logic
    IF v_facility.suspicion >= 100 THEN
        v_prison_time := NOW() + INTERVAL '15 minutes';
        
        -- Confiscate (Delete) completed products
        DELETE FROM public.facility_queue 
        WHERE facility_id = p_facility_id 
        AND completed_at <= v_now;
        
        UPDATE game.users 
        SET prison_until = v_prison_time, 
            prison_reason = 'Illegal Production (Suspicion 100%)' 
        WHERE id = v_user_id;
        UPDATE public.facilities SET suspicion = 0 WHERE id = p_facility_id;
        
        RETURN jsonb_build_object('success', false, 'error', 'POLICE RAID! Items confiscated. You are in prison.', 'in_prison', true);
    END IF;

    -- Loop Jobs
    FOR v_job IN 
        SELECT * FROM public.facility_queue 
        WHERE facility_id = p_facility_id 
        AND completed_at <= v_now
    LOOP
        SELECT * INTO v_recipe FROM public.facility_recipes WHERE id = v_job.recipe_id;
        
        IF v_recipe IS NOT NULL THEN
            -- Check if item exists in inventory (use item_id matching)
            SELECT row_id, quantity INTO v_existing_inv 
            FROM public.inventory 
            WHERE user_id = v_user_id AND item_id = v_recipe.output_item_id 
            LIMIT 1;
            
            IF v_existing_inv IS NOT NULL AND v_existing_inv.row_id IS NOT NULL THEN
                UPDATE public.inventory 
                SET quantity = quantity + (v_recipe.output_quantity * v_job.quantity)
                WHERE row_id = v_existing_inv.row_id;
            ELSE
                INSERT INTO public.inventory (user_id, item_id, quantity)
                VALUES (v_user_id, v_recipe.output_item_id, (v_recipe.output_quantity * v_job.quantity));
            END IF;
            
            v_collected_items := v_collected_items || jsonb_build_object('item', v_recipe.output_item_id, 'qty', v_recipe.output_quantity * v_job.quantity);
            v_count := v_count + 1;
        END IF;

        DELETE FROM public.facility_queue WHERE id = v_job.id;
    END LOOP;

    IF v_count = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'No completed production found (Wait for timer)');
    END IF;

    RETURN jsonb_build_object('success', true, 'collected', v_collected_items);

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ============================================================
-- create_get_player_facilities_rpc.sql
-- ============================================================

-- RPC: Get Player Facilities WITH Production Queue
-- Joins facilities with facility_queue to include active production jobs

CREATE OR REPLACE FUNCTION get_player_facilities_with_queue()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facilities JSONB;
    v_facility RECORD;
    v_queue_item RECORD;
    v_facility_obj JSONB;
    v_queue_array JSONB;
    v_facility_count INT := 0;
    v_queue_count INT := 0;
BEGIN
    v_user_id := auth.uid();
    RAISE NOTICE '[RPC] get_player_facilities_with_queue started. User: %', v_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '[RPC] ERROR: User not authenticated';
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    v_facilities := '[]'::jsonb;
    
    -- Get all facilities for this user
    RAISE NOTICE '[RPC] Fetching facilities for user: %', v_user_id;
    FOR v_facility IN 
        SELECT * FROM public.facilities 
        WHERE user_id = v_user_id 
        ORDER BY type ASC
    LOOP
        v_facility_count := v_facility_count + 1;
        RAISE NOTICE '[RPC] Processing facility #%: id=%, type=%', v_facility_count, v_facility.id, v_facility.type;
        
        -- Build queue array for this facility
        v_queue_array := '[]'::jsonb;
        v_queue_count := 0;
        
        RAISE NOTICE '[RPC] Fetching queue items for facility %', v_facility.id;
        FOR v_queue_item IN 
            SELECT * FROM public.facility_queue 
            WHERE facility_id = v_facility.id 
            ORDER BY started_at ASC
        LOOP
            v_queue_count := v_queue_count + 1;
            RAISE NOTICE '[RPC] Queue item #%: id=%, recipe=%, completed_at=%', 
                v_queue_count, v_queue_item.id, v_queue_item.recipe_id, v_queue_item.completed_at;
            
            v_queue_array := v_queue_array || jsonb_build_object(
                'id', v_queue_item.id,
                'facility_id', v_queue_item.facility_id,
                'recipe_id', v_queue_item.recipe_id,
                'quantity', v_queue_item.quantity,
                'started_at', v_queue_item.started_at,
                'completed_at', v_queue_item.completed_at,
                'status', v_queue_item.status,
                'is_raided', v_queue_item.is_raided,
                'is_burned', v_queue_item.is_burned
            );
        END LOOP;
        
        RAISE NOTICE '[RPC] Facility % has % queue items', v_facility.id, v_queue_count;
        
        -- Build facility object with queue
        RAISE NOTICE '[RPC] Building facility object for: %', v_facility.type;
        v_facility_obj := jsonb_build_object(
            'id', v_facility.id,
            'user_id', v_facility.user_id,
            'type', v_facility.type,
            'level', v_facility.level,
            'suspicion', v_facility.suspicion,
            'is_active', v_facility.is_active,
            'production_started_at', v_facility.production_started_at,
            'created_at', v_facility.created_at,
            'updated_at', v_facility.updated_at,
            'facility_queue', v_queue_array
        );
        
        v_facilities := v_facilities || jsonb_build_array(v_facility_obj);
    END LOOP;
    
    RAISE NOTICE '[RPC] Completed. Total facilities: %, facilities_json_keys: %', 
        v_facility_count, jsonb_array_length(v_facilities);
    RAISE NOTICE '[RPC] Final response data: %', v_facilities;
    
    RETURN jsonb_build_object('success', true, 'data', v_facilities);
END;
$$;

-- ============================================================
-- create_get_facility_recipes_rpc.sql
-- ============================================================

-- RPC: Get Facility Recipes (fixes facility_level_required column name error)
-- Returns recipes for a facility type with proper column names

CREATE OR REPLACE FUNCTION get_facility_recipes_rpc(p_facility_type TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_recipes JSONB := '[]'::jsonb;
    v_recipe RECORD;
    v_recipe_count INT := 0;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    IF p_facility_type IS NULL OR p_facility_type = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility type required');
    END IF;
    
    -- Get recipes for this facility type - uses required_level (correct column name)
    FOR v_recipe IN 
        SELECT 
            id, 
            facility_type, 
            output_item_id, 
            output_quantity, 
            input_materials, 
            gold_cost, 
            duration_seconds, 
            required_level,
            success_rate, 
            base_suspicion_increase,
            production_speed_bonus,
            rarity_distribution,
            created_at
        FROM public.facility_recipes 
        WHERE facility_type = p_facility_type
        ORDER BY required_level ASC
    LOOP
        v_recipe_count := v_recipe_count + 1;
        
        v_recipes := v_recipes || jsonb_build_object(
            'id', v_recipe.id,
            'facility_type', v_recipe.facility_type,
            'output_item_id', v_recipe.output_item_id,
            'output_quantity', v_recipe.output_quantity,
            'input_materials', v_recipe.input_materials,
            'gold_cost', v_recipe.gold_cost,
            'duration_seconds', v_recipe.duration_seconds,
            'required_level', v_recipe.required_level,
            'success_rate', v_recipe.success_rate,
            'base_suspicion_increase', v_recipe.base_suspicion_increase,
            'production_speed_bonus', v_recipe.production_speed_bonus,
            'rarity_distribution', v_recipe.rarity_distribution,
            'created_at', v_recipe.created_at
        );
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'recipes', v_recipes,
        'count', v_recipe_count,
        'facility_type', p_facility_type
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_facility_recipes_rpc(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_facility_recipes_rpc(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION get_facility_recipes_rpc(TEXT) TO service_role;

-- ============================================================
-- create_upgrade_facility_rpc.sql
-- ============================================================

-- RPC: Upgrade Facility
-- Handles cost calculation and level increment server-side

CREATE OR REPLACE FUNCTION upgrade_facility(
    p_facility_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_current_level INT;
    v_cost INT;
    v_user_gold INT;
    v_base_cost INT := 2000;
    v_multiplier FLOAT := 1.6;
BEGIN
    v_user_id := auth.uid();
    
    -- Get facility
    SELECT * INTO v_facility FROM public.facilities WHERE id = p_facility_id AND user_id = v_user_id;
    IF v_facility IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;
    
    v_current_level := v_facility.level;
    
    -- Calculate cost: 2000 * (1.6 ^ level)
    -- Note: Power returns float, cast to int
    v_cost := (v_base_cost * power(v_multiplier, v_current_level))::INT;
    
    -- Check user gold
    SELECT gold INTO v_user_gold FROM game.users WHERE id = v_user_id;
    
    IF v_user_gold < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gold', 'cost', v_cost, 'current_gold', v_user_gold);
    END IF;
    
    -- Deduct gold
    UPDATE game.users SET gold = gold - v_cost WHERE id = v_user_id;
    
    -- Increment level
    UPDATE public.facilities 
    SET level = level + 1, updated_at = NOW() 
    WHERE id = p_facility_id;
    
    -- Calculate next cost for UI convenience
    -- next_cost = 2000 * (1.6 ^ (level + 1))
    
    RETURN jsonb_build_object(
        'success', true, 
        'new_level', v_current_level + 1,
        'gold_deducted', v_cost,
        'remaining_gold', v_user_gold - v_cost,
        'next_upgrade_cost', (v_base_cost * power(v_multiplier, v_current_level + 1))::INT
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ============================================================
-- create_purchase_listing_rpc.sql
-- ============================================================

CREATE OR REPLACE FUNCTION public.purchase_market_listing(p_order_id UUID, p_quantity INT DEFAULT 1, p_is_stackable BOOLEAN DEFAULT FALSE)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_buyer_id UUID;
    v_seller_id UUID;
    v_total_price BIGINT;
    v_buyer_gold BIGINT;
    v_item_data JSONB;
    v_commission_rate NUMERIC := 0.05; -- 5% commission
    v_commission_amount BIGINT;
    v_seller_revenue BIGINT;
    v_seller_gold BIGINT;
    v_remaining_qty INT;
    v_transfer_qty INT;
    v_dest_slot INT;
    v_dest_qty INT;
    v_space INT;
    v_enhancement_level INT;
BEGIN
    -- Get current user (buyer)
    v_buyer_id := auth.uid();
    IF v_buyer_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Get Order
    SELECT * INTO v_order FROM public.market_orders WHERE id = p_order_id AND status = 'active' FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Listing not found or no longer active');
    END IF;

    v_seller_id := v_order.seller_id;
    
    -- Prevent self-trading
    IF v_seller_id = v_buyer_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot buy your own listing');
    END IF;
    
    -- Check Quantity
    IF p_quantity <= 0 THEN
         RETURN jsonb_build_object('success', false, 'error', 'Invalid quantity');
    END IF;
    
    IF v_order.quantity < p_quantity THEN
         RETURN jsonb_build_object('success', false, 'error', 'Not enough quantity available (Stock: ' || v_order.quantity || ')');
    END IF;

    -- Calculate Total Price
    v_total_price := v_order.price * p_quantity;
    
    -- Check Buyer Gold
    SELECT gold INTO v_buyer_gold FROM public.users WHERE auth_id = v_buyer_id OR id = v_buyer_id;
    
    IF v_buyer_gold < v_total_price THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not enough gold');
    END IF;

    -- Transaction
    -- 1. Deduct Gold from Buyer
    UPDATE public.users 
    SET gold = gold - v_total_price 
    WHERE auth_id = v_buyer_id OR id = v_buyer_id
    RETURNING gold INTO v_buyer_gold;
    
    -- 2. Add Gold to Seller (minus commission)
    v_commission_amount := FLOOR(v_total_price * v_commission_rate);
    v_seller_revenue := v_total_price - v_commission_amount;
    
    UPDATE public.users 
    SET gold = gold + v_seller_revenue 
    WHERE auth_id = v_seller_id OR id = v_seller_id
    RETURNING gold INTO v_seller_gold;
    
    -- 3. Transfer Item to Buyer with Stacking Logic
    v_item_data := v_order.item_data;
    v_enhancement_level := COALESCE((v_item_data->>'enhancement_level')::int, 0);
    v_remaining_qty := p_quantity;
    
    -- Handling Logic based on Stackability
    IF p_is_stackable THEN
        -- Legacy Stackable Logic (Potion, etc)
        WHILE v_remaining_qty > 0 LOOP
            v_dest_slot := NULL;
            v_dest_qty := 0;
            
            -- Try to find existing partial stack
            SELECT slot_position, quantity INTO v_dest_slot, v_dest_qty
            FROM public.inventory
            WHERE user_id = v_buyer_id 
              AND item_id = v_order.item_id
              AND enhancement_level = v_enhancement_level
              AND quantity < 50
            ORDER BY quantity DESC 
            LIMIT 1;
            
            IF v_dest_slot IS NOT NULL THEN
                -- Fill Existing Stack
                v_space := 50 - v_dest_qty;
                v_transfer_qty := LEAST(v_remaining_qty, v_space);
                
                UPDATE public.inventory 
                SET quantity = quantity + v_transfer_qty
                WHERE user_id = v_buyer_id AND slot_position = v_dest_slot;
                
                v_remaining_qty := v_remaining_qty - v_transfer_qty;
            ELSE
                -- New Slot
                SELECT MIN(slot_num) INTO v_dest_slot
                FROM generate_series(0, 19) slot_num
                WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_buyer_id AND slot_position = slot_num);
                
                IF v_dest_slot IS NULL THEN
                    RAISE EXCEPTION 'Inventory full';
                END IF;
                
                v_transfer_qty := LEAST(v_remaining_qty, 50);
                
                INSERT INTO public.inventory (
                    user_id, item_id, quantity, slot_position, 
                    enhancement_level, is_equipped, obtained_at
                )
                VALUES (
                    v_buyer_id, 
                    v_order.item_id, 
                    v_transfer_qty, 
                    v_dest_slot, 
                    v_enhancement_level,
                    false,
                    EXTRACT(EPOCH FROM NOW())::bigint
                );
                
                v_remaining_qty := v_remaining_qty - v_transfer_qty;
            END IF;
        END LOOP;
        
    ELSE
        -- Non-Stackable Logic (Equipment)
        -- Must find separate slots for EACH item if p_quantity > 1 (unlikely for equip, but safe to handle)
        FOR i IN 1..p_quantity LOOP
             -- Find ONE empty slot
             v_dest_slot := NULL;
             SELECT MIN(slot_num) INTO v_dest_slot
             FROM generate_series(0, 19) slot_num
             WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_buyer_id AND slot_position = slot_num);
             
             IF v_dest_slot IS NULL THEN
                 RAISE EXCEPTION 'Inventory full';
             END IF;
             
             INSERT INTO public.inventory (
                user_id, item_id, quantity, slot_position, 
                enhancement_level, is_equipped, obtained_at
            )
            VALUES (
                v_buyer_id, 
                v_order.item_id, 
                1, -- Always 1 for non-stackable
                v_dest_slot, 
                v_enhancement_level,
                false,
                EXTRACT(EPOCH FROM NOW())::bigint
            );
        END LOOP;
    END IF;
    
    -- 4. Update or Delete Order
    IF v_order.quantity = p_quantity THEN
        DELETE FROM public.market_orders WHERE id = p_order_id;
    ELSE
        UPDATE public.market_orders SET quantity = quantity - p_quantity WHERE id = p_order_id;
    END IF;
    
    -- 5. Track History
    INSERT INTO public.market_history (item_id, seller_id, buyer_id, price, quantity, sold_at)
    VALUES (v_order.item_id, v_seller_id, v_buyer_id, v_order.price, p_quantity, NOW());
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Item purchased',
        'new_buyer_gold', v_buyer_gold,
        'new_seller_gold', v_seller_gold
    );

EXCEPTION 
    WHEN OTHERS THEN
         IF SQLERRM = 'Inventory full' THEN
             RETURN jsonb_build_object('success', false, 'error', 'Inventory full');
         END IF;
         RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ============================================================
-- add_collect_facility_resources_rpc.sql
-- ============================================================

-- ============================================
-- RPC: Collect Facility Resources (Server-Side Calculation)
-- ============================================

CREATE OR REPLACE FUNCTION public.collect_facility_resources(
    p_facility_id UUID,
    p_resources JSONB DEFAULT '[]'::jsonb -- Kept for signature compatibility, ignored
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_resources_generated JSONB := '[]'::jsonb;
    v_item RECORD;
    v_existing_item RECORD;
    v_items_inserted INT := 0;
    v_items_updated INT := 0;
    v_items_skipped INT := 0;
    v_to_add JSONB := '{}'::jsonb;
    v_required_slots INT := 0;
    v_available_slots INT := 0;
        v_available_slot_list INT[] := ARRAY[]::int[];
        v_slot_idx INT := 1;
    v_qty_to_add INT := 0;
    v_qty_remaining INT := 0;
    v_max_stack INT := 999;
    v_is_stackable BOOLEAN := true;
    v_existing_space INT := 0;
    v_item_id TEXT;
    v_add_qty INT := 0;
    
    -- Time Logic
    v_now TIMESTAMP WITH TIME ZONE := NOW();
    v_last_collected TIMESTAMP WITH TIME ZONE;
    v_started_at TIMESTAMP WITH TIME ZONE;
    v_hours_elapsed FLOAT;
    v_production_rate INT;
    v_total_qty INT;
    v_offline_cap INT := 720;
    v_production_duration_seconds NUMERIC := 120;  -- 2 minutes for testing (originally 3600 = 1 hour)
    v_calc_end TIMESTAMP WITH TIME ZONE;
    v_elapsed_since_start NUMERIC;
    
    -- Drop Rate Variables
    v_level INT;
    v_base_rate INT := 10;
    v_roll FLOAT;
    v_rarity TEXT;
    
    -- Weights (Base Level 1 - Matched with FacilityManager.gd)
    v_w_common FLOAT := 700.0;
    v_w_uncommon FLOAT := 200.0;
    v_w_rare FLOAT := 80.0;
    v_w_epic FLOAT := 15.0;
    v_w_legendary FLOAT := 5.0;
    v_total_weight FLOAT;
    
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- CHECK IF PLAYER IS IN PRISON
    IF EXISTS (
        SELECT 1 FROM public.prison_records 
        WHERE user_id = v_user_id AND released_at IS NULL
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Player is imprisoned and cannot collect resources');
    END IF;

    -- Verify facility ownership
    SELECT * INTO v_facility
    FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;

    v_level := COALESCE(v_facility.level, 1);
    v_started_at := v_facility.production_started_at;
    v_last_collected := COALESCE(v_facility.last_production_collected_at, v_started_at);

    -- Production Validation
    IF v_started_at IS NULL THEN
         RETURN jsonb_build_object('success', false, 'error', 'Production not started');
    END IF;
    
    -- CRITICAL: If last_collected is same as started, use started time (first collection from production start)
    -- Otherwise use the actual last collection time
    IF v_last_collected IS NULL THEN
        v_last_collected := v_started_at;
    END IF;
    IF v_last_collected < v_started_at THEN
        v_last_collected := v_started_at;
    END IF;
    
    -- Cap calculation to production duration window
    v_calc_end := LEAST(v_now, v_started_at + (v_production_duration_seconds || ' seconds')::interval);
    IF v_last_collected >= v_calc_end THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'No resources accumulated yet',
            'count', 0,
            'items_inserted', 0,
            'items_updated', 0,
            'items_skipped', 0,
            'debug_started_at', v_started_at,
            'debug_last_collected', v_last_collected,
            'debug_calc_end', v_calc_end
        );
    END IF;
    
    -- Calculate hours elapsed since last collection
    v_hours_elapsed := EXTRACT(EPOCH FROM (v_calc_end - v_last_collected)) / 3600.0;
    
    RAISE NOTICE '[collect_facility_resources] DEBUG: started_at=%, last_collected=%, calc_end=%, hours_elapsed=%, now=%', v_started_at, v_last_collected, v_calc_end, v_hours_elapsed, v_now;
    
    -- Resources accumulate continuously: (hours_elapsed * base_rate * level * 10x multiplier)
    v_production_rate := v_base_rate * v_level * 10;  -- 10x for testing
    v_total_qty := GREATEST(0, (v_hours_elapsed * v_production_rate)::INT);
    
    RAISE NOTICE '[collect_facility_resources] CALC: hours_elapsed=%, rate=%, total_qty=%', v_hours_elapsed, v_production_rate, v_total_qty;
    
    -- If no time has passed, no resources
    IF v_total_qty <= 0 THEN
        RETURN jsonb_build_object('success', true, 'message', 'No resources accumulated yet', 'count', 0);
    END IF;
    
    -- Cap by offline production cap
    v_total_qty := LEAST(v_total_qty, v_offline_cap);
    
    -- Adjust Weights Scaling by Level (Sync with FacilityManager.gd)
    IF v_level > 1 THEN
        v_w_uncommon := v_w_uncommon + ((v_level - 1) * 15.0);
        v_w_rare := v_w_rare + ((v_level - 1) * 8.0);
        v_w_epic := v_w_epic + ((v_level - 1) * 3.0);
        v_w_legendary := v_w_legendary + ((v_level - 1) * 1.5);
    END IF;
    
    v_total_weight := v_w_common + v_w_uncommon + v_w_rare + v_w_epic + v_w_legendary;

    RAISE NOTICE '[collect_facility_resources] Start: user_id=%, facility_type=%, level=%, total_qty=%', v_user_id, v_facility.type, v_level, v_total_qty;
    
    -- Generate Items loop
    FOR i IN 1..v_total_qty LOOP
        v_roll := random() * v_total_weight;
        
        IF v_roll < v_w_common THEN v_rarity := 'common';
        ELSIF v_roll < (v_w_common + v_w_uncommon) THEN v_rarity := 'uncommon';
        ELSIF v_roll < (v_w_common + v_w_uncommon + v_w_rare) THEN v_rarity := 'rare';
        ELSIF v_roll < (v_w_common + v_w_uncommon + v_w_rare + v_w_epic) THEN v_rarity := 'epic';
        ELSE v_rarity := 'legendary';
        END IF;
        
                -- Select Item based on Facility Type & Rarity (case-insensitive)
                SELECT * INTO v_item
                FROM public.items
                WHERE production_building_type = v_facility.type
                    AND lower(rarity) = v_rarity
                ORDER BY random()
                LIMIT 1;
        
                -- Fallback if not found
                IF NOT FOUND THEN
                        RAISE NOTICE '[collect_facility_resources] No item found for type=% rarity=%, trying common', v_facility.type, v_rarity;
                        SELECT * INTO v_item
                        FROM public.items
                        WHERE production_building_type = v_facility.type
                            AND lower(rarity) = 'common'
                        ORDER BY random()
                        LIMIT 1;
                END IF;

                -- Final fallback: any item for this facility type
                IF NOT FOUND THEN
                    RAISE NOTICE '[collect_facility_resources] No rarity match, picking any item for type=%', v_facility.type;
                    SELECT * INTO v_item
                    FROM public.items
                    WHERE production_building_type = v_facility.type
                    ORDER BY random()
                    LIMIT 1;
                END IF;

                -- Last resort: pick any item at all (prevents zero inserts if type mapping is missing)
                IF NOT FOUND THEN
                    RAISE NOTICE '[collect_facility_resources] No item found for type=%, picking any item globally', v_facility.type;
                    SELECT * INTO v_item
                    FROM public.items
                    ORDER BY random()
                    LIMIT 1;
                END IF;
        
        IF FOUND THEN
            RAISE NOTICE '[collect_facility_resources] Item found: id=%, name=%, stackable=%, rarity=%', v_item.id, v_item.name, v_item.is_stackable, v_item.rarity;
            v_to_add := jsonb_set(
                v_to_add,
                ARRAY[v_item.id::text],
                to_jsonb(COALESCE((v_to_add->>v_item.id::text)::int, 0) + 1),
                true
            );
        ELSE
            v_items_skipped := v_items_skipped + 1;
            RAISE NOTICE '[collect_facility_resources] WARNING: No item found even in fallback for type=%', v_facility.type;
        END IF;
    END LOOP;
    
    RAISE NOTICE '[collect_facility_resources] Loop complete: processed % items', v_total_qty;

    -- ===== Inventory capacity check (20 slots) =====
    -- Count only valid slot positions (0-19)
    SELECT COUNT(*) INTO v_available_slots
    FROM public.inventory
    WHERE user_id = v_user_id
      AND slot_position BETWEEN 0 AND 19;
    v_available_slots := 20 - v_available_slots;
    IF v_available_slots < 0 THEN
        v_available_slots := 0;
    END IF;

    -- Calculate required slots based on stacking rules
    FOR v_item_id, v_qty_to_add IN
        SELECT key, value::int FROM jsonb_each_text(v_to_add)
    LOOP
        -- FACILITY ITEMS: All facility-produced items MUST stack with max=500
        -- Do NOT read from database - use fixed values
        v_is_stackable := true;
        v_max_stack := 500;

        IF v_is_stackable THEN
            SELECT COALESCE(SUM(GREATEST(v_max_stack - quantity, 0)), 0)
            INTO v_existing_space
            FROM public.inventory
            WHERE user_id = v_user_id AND item_id = v_item_id;

            v_qty_remaining := GREATEST(v_qty_to_add - v_existing_space, 0);
            IF v_qty_remaining > 0 THEN
                v_required_slots := v_required_slots + CEIL(v_qty_remaining::numeric / v_max_stack::numeric)::int;
            END IF;
        ELSE
            v_required_slots := v_required_slots + v_qty_to_add;
        END IF;
    END LOOP;

    -- Build available slot list (0-19)
    SELECT ARRAY_AGG(slot_num ORDER BY slot_num)
    INTO v_available_slot_list
    FROM generate_series(0, 19) slot_num
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory
        WHERE user_id = v_user_id AND slot_position = slot_num
    );

    -- Recalculate available slots based on actual free positions
    v_available_slots := COALESCE(array_length(v_available_slot_list, 1), 0);

    IF v_required_slots > v_available_slots THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Inventory is full',
            'required_slots', v_required_slots,
            'available_slots', v_available_slots,
            'count', v_total_qty,
            'items_inserted', 0,
            'items_updated', 0,
            'items_skipped', v_items_skipped,
            'debug_started_at', v_started_at,
            'debug_last_collected', v_last_collected,
            'debug_calc_end', v_calc_end,
            'debug_hours_elapsed', v_hours_elapsed,
            'debug_rate', v_production_rate
        );
    END IF;

    -- ===== Apply additions =====
    FOR v_item_id, v_qty_to_add IN
        SELECT key, value::int FROM jsonb_each_text(v_to_add)
    LOOP

        -- FACILITY ITEMS: Force max_stack=500 for all facility-produced items
        v_is_stackable := true;
        v_max_stack := 500;

        RAISE NOTICE '[collect_facility_resources] Item %: stackable=%, max_stack=%', v_item_id, v_is_stackable, v_max_stack;

        IF v_is_stackable THEN
            v_qty_remaining := v_qty_to_add;

            -- Fill existing stacks first
            FOR v_existing_item IN
                SELECT row_id, quantity, slot_position
                FROM public.inventory
                WHERE user_id = v_user_id AND item_id = v_item_id
                ORDER BY quantity ASC
            LOOP
                v_add_qty := LEAST(v_max_stack - v_existing_item.quantity, v_qty_remaining);
                IF v_add_qty > 0 THEN
                    UPDATE public.inventory
                    SET quantity = quantity + v_add_qty, updated_at = NOW()
                    WHERE row_id = v_existing_item.row_id;
                    v_qty_remaining := v_qty_remaining - v_add_qty;
                    v_items_updated := v_items_updated + 1;
                END IF;
                IF v_qty_remaining <= 0 THEN
                    EXIT;
                END IF;
            END LOOP;

            -- Insert new stacks if needed
            WHILE v_qty_remaining > 0 LOOP
                v_add_qty := LEAST(v_max_stack, v_qty_remaining);
                INSERT INTO public.inventory (
                    user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position
                ) VALUES (
                    v_user_id, v_item_id, v_add_qty, 0, false, EXTRACT(EPOCH FROM NOW())::BIGINT,
                    v_available_slot_list[v_slot_idx]
                );
                v_items_inserted := v_items_inserted + 1;
                v_slot_idx := v_slot_idx + 1;
                v_qty_remaining := v_qty_remaining - v_add_qty;
            END LOOP;
        ELSE
            -- Non-stackable: each needs its own slot
            FOR i IN 1..v_qty_to_add LOOP
                INSERT INTO public.inventory (
                    user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position
                ) VALUES (
                    v_user_id, v_item_id, 1, 0, false, EXTRACT(EPOCH FROM NOW())::BIGINT,
                    v_available_slot_list[v_slot_idx]
                );
                v_items_inserted := v_items_inserted + 1;
                v_slot_idx := v_slot_idx + 1;
            END LOOP;
        END IF;
    END LOOP;

    -- Update Facility
    -- Update last_production_collected_at to NOW
    -- Reset production_started_at ONLY if 120 seconds have passed (status=expired)
    -- Otherwise keep production_started_at so production continues from where it left off
    
    BEGIN
        v_elapsed_since_start := EXTRACT(EPOCH FROM (v_now - v_started_at));
        RAISE NOTICE '[collect_facility_resources] Updating facility: elapsed_since_start=%, duration=%', v_elapsed_since_start, v_production_duration_seconds;
        
        IF v_elapsed_since_start >= v_production_duration_seconds THEN
            -- Production expired (120 seconds passed), reset for next cycle
            RAISE NOTICE '[collect_facility_resources] Production expired, resetting production_started_at';
            UPDATE public.facilities
            SET last_production_collected_at = v_now,
                production_started_at = NULL,
                suspicion = GREATEST(0, suspicion - GREATEST(5, (suspicion * 0.15)::INT))
            WHERE id = p_facility_id;
        ELSE
            -- Production still active (under 120 seconds), keep production_started_at
            RAISE NOTICE '[collect_facility_resources] Production still active, keeping production_started_at';
            UPDATE public.facilities
            SET last_production_collected_at = v_now,
                suspicion = GREATEST(0, suspicion - GREATEST(5, (suspicion * 0.15)::INT))
            WHERE id = p_facility_id;
        END IF;
    END;

    RAISE NOTICE '[collect_facility_resources] SUCCESS: collected %, inserted=%, updated=%', v_total_qty, v_items_inserted, v_items_updated;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Resources collected',
        'count', v_total_qty,
        'items_inserted', v_items_inserted,
        'items_updated', v_items_updated,
        'items_skipped', v_items_skipped,
        'debug_started_at', v_started_at,
        'debug_last_collected', v_last_collected,
        'debug_calc_end', v_calc_end,
        'debug_hours_elapsed', v_hours_elapsed,
        'debug_rate', v_production_rate,
        'new_suspicion', GREATEST(0, v_facility.suspicion - GREATEST(5, (v_facility.suspicion * 0.15)::INT))
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[collect_facility_resources] ERROR: %', SQLERRM;
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
