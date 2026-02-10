-- ============================================================
-- SUPABASE SQL EDİTÖR - VERİTABANI KURTARMA
-- ============================================================
-- DOSYA 1/5: TEMEL ALTYAPI
-- ============================================================
-- 
-- Bu dosya veritabanının temel iskeletini oluşturur:
-- ✓ Envanter tablosu (inventory)
-- ✓ Öğeler tablosu (items)
-- ✓ Ekipman sistemi
-- ✓ Slot pozisyon RPC'leri
-- ✓ Hastane fonksiyonları
--
-- TALİMATLAR:
-- 1. Bu dosyanın tüm içeriğini kopyalayın (Ctrl+A, Ctrl+C)
-- 2. Supabase SQL Editor'e gidin:
--    https://app.supabase.com/project/znvsyzstmxhqvdkkmgdt/sql
-- 3. SQL Editor'e yapıştırın (Ctrl+V)
-- 4. RUN butonuna basın
-- 5. İşlem tamamlanana kadar bekleyin (~30 saniye)
-- 6. Sonra 02_DUZELTMELER.sql dosyasına geçin
--
-- BEKLENEN SÜRE: ~30 saniye
-- BEKLENEN SONUÇ: items ve inventory tabloları oluşturuldu
-- ============================================================

-- UPDATE EXISTING INVENTORY TABLE
-- This script safely adds missing columns to your existing 'inventory' table.
-- It will NOT delete any data. It only ensures your table has the columns required by the new ItemData.gd code.

do $$
begin
    -- 1. Essential Columns
    -- 'description' and 'icon' are new in the enhanced ItemData
    alter table public.inventory add column if not exists description text;
    alter table public.inventory add column if not exists icon text;
    
    -- 2. Sub-types (Enums stored as text)
    -- Needed to avoid "Could not find column 'armor_type'" errors
    alter table public.inventory add column if not exists weapon_type text;
    alter table public.inventory add column if not exists armor_type text;
    alter table public.inventory add column if not exists material_type text;
    alter table public.inventory add column if not exists potion_type text;
    
    -- 3. Economy
    alter table public.inventory add column if not exists base_price int default 0;
    alter table public.inventory add column if not exists vendor_sell_price int default 0;
    alter table public.inventory add column if not exists is_tradeable boolean default true;
    alter table public.inventory add column if not exists is_stackable boolean default true;
    alter table public.inventory add column if not exists max_stack int default 999;
    
    -- 4. Enhancement & Stats
    alter table public.inventory add column if not exists max_enhancement int default 0;
    alter table public.inventory add column if not exists can_enhance boolean default false;
    alter table public.inventory add column if not exists heal_amount int default 0;
    alter table public.inventory add column if not exists tolerance_increase int default 0;
    alter table public.inventory add column if not exists overdose_risk float default 0.0;
    
    -- 5. Requirements
    alter table public.inventory add column if not exists required_level int default 0;
    alter table public.inventory add column if not exists required_class text;
    
    -- 6. Crafting / Recipes (JSONB is best for flexibility)
    alter table public.inventory add column if not exists recipe_requirements jsonb default '{}'::jsonb;
    alter table public.inventory add column if not exists recipe_result_item_id text;
    alter table public.inventory add column if not exists recipe_building_type text;
    alter table public.inventory add column if not exists recipe_production_time int default 0;
    alter table public.inventory add column if not exists recipe_required_level int default 0;
    
    -- 7. Rune System
    alter table public.inventory add column if not exists rune_enhancement_type text;
    alter table public.inventory add column if not exists rune_success_bonus float default 0.0;
    alter table public.inventory add column if not exists rune_destruction_reduction float default 0.0;
    
    -- 8. Cosmetics
    alter table public.inventory add column if not exists cosmetic_effect text;
    alter table public.inventory add column if not exists cosmetic_bind_on_pickup boolean default false;
    alter table public.inventory add column if not exists cosmetic_showcase_only boolean default false;
    
    -- 9. Production
    alter table public.inventory add column if not exists production_building_type text;
    alter table public.inventory add column if not exists production_rate_per_hour int default 0;
    alter table public.inventory add column if not exists production_required_level int default 0;
    
    -- 10. Sync State
    alter table public.inventory add column if not exists bound_to_player boolean default false;
    alter table public.inventory add column if not exists pending_sync boolean default false;

exception
    when others then
        raise notice 'Error updating columns: %', SQLERRM;
end;
$$;

-- ============================================================
-- DOSYA 2/5: Normalizasyon ve RPC Fonksiyonları
-- ============================================================


-- ============================================================
-- DOSYA 3/5: Ekipman Sistemi
-- ============================================================


-- ============================================================
-- DOSYA 5/5: Hastane Fonksiyonları
-- ============================================================


-- ============================================================
-- DOSYA 4/5: Slot Pozisyon RPC'leri
-- ============================================================

-- STEP 1: Ensure tables exist and match the Game's needs
-- We are using the 'public' schema to match standard Supabase REST access.
-- If your tables are in 'game' schema, please change 'public' to 'game' and ensure schema is exposed in API settings.

-- A. ITEMS TABLE (Definitions)
create table if not exists public.items (
    id text primary key, -- e.g. 'weapon_custom_longsword'
    name text not null,
    description text,
    icon text, -- New
    
    -- Types
    type text, -- e.g. 'WEAPON'
    rarity text,
    equip_slot text, -- New
    
    -- Subtypes (New columns needed for game logic)
    weapon_type text,
    armor_type text,
    material_type text,
    potion_type text,
    
    -- Stats
    attack int default 0,
    defense int default 0,
    health int default 0,
    power int default 0,
    energy_restore int default 0,
    heal_amount int default 0,
    
    -- Enhancement
    can_enhance boolean default false,
    max_enhancement int default 0,
    
    -- Economy
    base_price int default 0,
    vendor_sell_price int default 0,
    is_tradeable boolean default true,
    is_stackable boolean default true,
    max_stack int default 999,
    
    created_at timestamptz default now()
);

-- Sync columns just in case table existed but was missing fields
do $$
begin
    alter table public.items add column if not exists icon text;
    alter table public.items add column if not exists equip_slot text;
    alter table public.items add column if not exists weapon_type text;
    alter table public.items add column if not exists armor_type text;
    alter table public.items add column if not exists material_type text;
    alter table public.items add column if not exists potion_type text;
    alter table public.items add column if not exists attack int default 0;
    alter table public.items add column if not exists defense int default 0;
    alter table public.items add column if not exists health int default 0;
    alter table public.items add column if not exists power int default 0;
    alter table public.items add column if not exists energy_restore int default 0;
    alter table public.items add column if not exists heal_amount int default 0;
    alter table public.items add column if not exists can_enhance boolean default false;
    alter table public.items add column if not exists max_enhancement int default 0;
    alter table public.items add column if not exists base_price int default 0;
    alter table public.items add column if not exists vendor_sell_price int default 0;
    alter table public.items add column if not exists is_tradeable boolean default true;
    alter table public.items add column if not exists is_stackable boolean default true;
    alter table public.items add column if not exists max_stack int default 999;
    -- Add missing columns for full game support
    alter table public.items add column if not exists required_level int default 1;
    alter table public.items add column if not exists required_class text;
    alter table public.items add column if not exists tolerance_increase int default 0;
    alter table public.items add column if not exists overdose_risk numeric default 0;
    alter table public.items add column if not exists production_building_type text;
end $$;


-- B. INVENTORY TABLE (Player ownership)
create table if not exists public.inventory (
    row_id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users default auth.uid(),
    
    -- Link to Definition
    item_id text references public.items(id),
    
    -- Instance Data
    quantity int default 1,
    enhancement_level int default 0,
    is_equipped boolean default false,
    equip_slot text, -- Can override item default
    
    -- Metadata
    obtained_at bigint,
    is_favorite boolean default false,
    
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- B.2. MIGRATION: Fix inventory table schema
-- The previous script may have used 'id' for the item identifier string. 
-- The new standard uses 'item_id' for the identifier and 'row_id' (or 'id') for the UUID PK.
do $$
begin
    -- 1. Check if 'item_id' exists. If not, add it.
    if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'inventory' and column_name = 'item_id') then
        alter table public.inventory add column item_id text references public.items(id);
        
        -- 2. Migrate data from 'id' if 'id' looks like an item text ID (not a UUID)
        -- We blindly attempt copy if 'id' is text type.
        if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'inventory' and column_name = 'id' and data_type = 'text') then
             
             -- CRITICAL FIX: Ensure items exist in 'items' table before linking
             -- If inventory has 'weapon_sword_basic' but items table doesn't, FK will fail.
             -- We insert placeholders for any missing items found in the old inventory.
             insert into public.items (id, name, type)
             select distinct old_inv.id, 'Migrated Item ' || old_inv.id, 'MISC'
             from public.inventory old_inv
             where old_inv.id is not null 
               and not exists (select 1 from public.items it where it.id = old_inv.id);

             -- Now safely update the FK column
             update public.inventory set item_id = id where item_id is null;
        end if;
    end if;
    
    -- 3. Fix old 'id' column constraint - remove NOT NULL if it exists
    -- This handles the case where an old 'id' text column has NOT NULL constraint
    begin
        -- Try to drop NOT NULL constraint if it exists (PostgreSQL doesn't have a simple IF EXISTS for constraints)
        if exists (select 1 from information_schema.columns 
                   where table_schema = 'public' and table_name = 'inventory' 
                   and column_name = 'id' and data_type = 'text'
                   and is_nullable = 'NO') then
            alter table public.inventory alter column id drop not null;
        end if;
    exception when others then
        -- If constraint doesn't exist or can't be dropped, continue
        null;
    end;
    
    -- 4. Ensure required columns exist
    alter table public.inventory add column if not exists is_equipped boolean default false;
    alter table public.inventory add column if not exists enhancement_level int default 0;
end $$;

-- Enable RLS
alter table public.items enable row level security;
alter table public.inventory enable row level security;

-- Policies (Public Items are readable by everyone, Inventory is private)
-- Drop existing policies if they exist, then recreate them
drop policy if exists "Items are viewable by everyone" on public.items;
create policy "Items are viewable by everyone" on public.items for select using (true);

drop policy if exists "Items insertable by authenticated" on public.items;
create policy "Items insertable by authenticated" on public.items for insert with check (auth.role() = 'authenticated'); -- Or restrict to service_role

drop policy if exists "Users manage own inventory" on public.inventory;
create policy "Users manage own inventory" on public.inventory for all using (auth.uid() = user_id);


-- STEP 2: RPC Function to handle "Fat" Item Objects
-- This function splits the data: Saves definition to 'items', instance to 'inventory'.
-- Updated to handle float-string-to-int casting issues (::numeric::int)

-- Helper function to safely convert JSONB numeric values to integer
-- Handles integers, floats (1.0), and string representations ("1.0")
create or replace function public._jsonb_to_int(val jsonb, default_val int default 0) returns int as $$
declare
    text_val text;
begin
    -- Check for null
    if val is null or val = 'null'::jsonb then
        return default_val;
    end if;
    
    -- Try direct cast first (for integer JSONB values)
    begin
        return (val)::int;
    exception when others then
        -- Try as numeric first (handles float JSONB like 1.0)
        begin
            return (val::numeric)::int;
        exception when others then
            -- Try as text first, then numeric, then int (handles string "1.0")
            begin
                text_val := val::text;
                -- Remove quotes if present
                text_val := trim(both '"' from text_val);
                return (text_val::numeric)::int;
            exception when others then
                return default_val;
            end;
        end;
    end;
end;
$$ language plpgsql immutable;

create or replace function public.add_inventory_item(item_data jsonb)
returns jsonb
language plpgsql
security definer
as $$
declare
    v_item_id text;
    v_user_id uuid;
    v_quantity int;
    v_new_row jsonb;
begin
    -- Get User ID
    v_user_id := auth.uid();
    if v_user_id is null then
        return '{"success": false, "error": "Not authenticated"}'::jsonb;
    end if;

    -- Extract Key Data
    v_item_id := item_data->>'id';
    if v_item_id is null or v_item_id = '' then
        return '{"success": false, "error": "item_id is required"}'::jsonb;
    end if;
    
    -- Safe CAST for quantity (handles "1.0" string from JSON, floats, and integers)
    v_quantity := public._jsonb_to_int(item_data->'quantity', 1);

    -- 1. Upsert Item Definition (Ensure item exists in DB)
    -- We update the definition to match the client's latest data
    insert into public.items (
        id, name, description, icon, type, rarity, equip_slot,
        weapon_type, armor_type, material_type, potion_type,
        attack, defense, health, power, energy_restore, heal_amount,
        base_price, vendor_sell_price, can_enhance, max_enhancement,
        is_tradeable, is_stackable, max_stack,
        required_level, required_class, tolerance_increase, overdose_risk, production_building_type
    ) values (
        v_item_id,
        item_data->>'name',
        item_data->>'description',
        item_data->>'icon',
        item_data->>'item_type',
        item_data->>'rarity',
        item_data->>'equip_slot',
        item_data->>'weapon_type',
        item_data->>'armor_type',
        item_data->>'material_type',
        item_data->>'potion_type',
        public._jsonb_to_int(item_data->'attack', 0),
        public._jsonb_to_int(item_data->'defense', 0),
        public._jsonb_to_int(item_data->'health', 0),
        public._jsonb_to_int(item_data->'power', 0),
        public._jsonb_to_int(item_data->'energy_restore', 0),
        public._jsonb_to_int(item_data->'heal_amount', 0),
        public._jsonb_to_int(item_data->'base_price', 0),
        public._jsonb_to_int(item_data->'vendor_sell_price', 0),
        coalesce((item_data->>'can_enhance')::boolean, false),
        public._jsonb_to_int(item_data->'max_enhancement', 0),
        coalesce((item_data->>'is_tradeable')::boolean, true),
        coalesce((item_data->>'is_stackable')::boolean, true),
        public._jsonb_to_int(item_data->'max_stack', 999),
        public._jsonb_to_int(item_data->'required_level', 1),
        item_data->>'required_class',
        public._jsonb_to_int(item_data->'tolerance_increase', 0),
        coalesce((item_data->>'overdose_risk')::numeric, 0),
        item_data->>'production_building_type'
    )
    on conflict (id) do update set
        name = excluded.name,
        description = excluded.description,
        icon = excluded.icon,
        attack = excluded.attack,
        defense = excluded.defense,
        health = excluded.health,
        power = excluded.power,
        energy_restore = excluded.energy_restore,
        heal_amount = excluded.heal_amount,
        base_price = excluded.base_price,
        vendor_sell_price = excluded.vendor_sell_price,
        required_level = excluded.required_level,
        required_class = excluded.required_class,
        tolerance_increase = excluded.tolerance_increase,
        overdose_risk = excluded.overdose_risk,
        production_building_type = excluded.production_building_type
    where items.id = excluded.id;  -- Ensure we only update the matching row

    -- 2. Upsert Inventory Record
    -- Ensure required columns exist (migration checks)
    -- Note: ALTER TABLE cannot be executed inside a function transaction, so we handle this before the function
    -- For now, we'll ensure the insert works by using only columns that should exist
    
    -- Validate that item_id is not null (extracted above)
    if v_item_id is null or v_item_id = '' then
        return '{"success": false, "error": "item_id cannot be null or empty"}'::jsonb;
    end if;
    
    -- Check if item is stackable from items definition
    declare
        v_is_stackable boolean;
    begin
        select coalesce(is_stackable, true) into v_is_stackable
        from public.items
        where id = v_item_id;
        
        -- If item is stackable AND player already has it, increase quantity
        -- If item is NOT stackable (equipment), always insert new row
        if v_is_stackable and exists (select 1 from public.inventory where user_id = v_user_id and item_id = v_item_id) then
            update public.inventory
            set quantity = quantity + v_quantity,
                updated_at = now()
            where user_id = v_user_id and item_id = v_item_id
            returning to_jsonb(inventory.*) into v_new_row;
        else
            -- Insert new item (for non-stackable items or first-time stackable items)
            -- Handle case where old 'id' column might exist and need a value
            declare
                v_has_old_id_column boolean;
            begin
                -- Check if old 'id' text column exists
                select exists (
                    select 1 from information_schema.columns 
                    where table_schema = 'public' 
                    and table_name = 'inventory' 
                    and column_name = 'id' 
                    and data_type = 'text'
                ) into v_has_old_id_column;
                
                if v_has_old_id_column then
                    -- Insert with old 'id' column set to item_id value
                    insert into public.inventory (
                        user_id, item_id, id, quantity, enhancement_level, is_equipped, obtained_at
                    ) values (
                        v_user_id,
                        v_item_id,
                        v_item_id,  -- Set old 'id' column to item_id value
                        v_quantity,
                        public._jsonb_to_int(item_data->'enhancement_level', 0),
                        false,
                        extract(epoch from now())::bigint
                    )
                    returning to_jsonb(inventory.*) into v_new_row;
                else
                    -- Standard insert without old 'id' column
                    insert into public.inventory (
                        user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at
                    ) values (
                        v_user_id,
                        v_item_id,
                        v_quantity,
                        public._jsonb_to_int(item_data->'enhancement_level', 0),
                        false,
                        extract(epoch from now())::bigint
                    )
                    returning to_jsonb(inventory.*) into v_new_row;
                end if;
            end;
        end if;
    end;

    return jsonb_build_object('success', true, 'data', v_new_row);
end;
$$;

-- RPC Function to get player inventory
create or replace function public.get_inventory()
returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_inventory jsonb;
begin
    -- Get User ID
    v_user_id := auth.uid();
    if v_user_id is null then
        return '{"success": false, "error": "Not authenticated"}'::jsonb;
    end if;

    -- Fetch inventory items with their definitions
    select jsonb_agg(
        jsonb_build_object(
            'row_id', inv.row_id,
            'id', inv.item_id,  -- Use item_id as the main id for client
            'item_id', inv.item_id,
            'quantity', inv.quantity,
            'enhancement_level', coalesce(inv.enhancement_level, 0),
            'is_equipped', coalesce(inv.is_equipped, false),
            'equip_slot', inv.equip_slot,
            'obtained_at', inv.obtained_at,
            'is_favorite', coalesce(inv.is_favorite, false),
            -- Merge item definition data
            'name', it.name,
            'description', it.description,
            'icon', it.icon,
            'item_type', it.type,
            'rarity', it.rarity,
            'weapon_type', it.weapon_type,
            'armor_type', it.armor_type,
            'material_type', it.material_type,
            'potion_type', it.potion_type,
            'attack', it.attack,
            'defense', it.defense,
            'health', it.health,
            'power', it.power,
            'energy_restore', it.energy_restore,
            'heal_amount', it.heal_amount,
            'base_price', it.base_price,
            'vendor_sell_price', it.vendor_sell_price,
            'can_enhance', it.can_enhance,
            'max_enhancement', it.max_enhancement,
            'is_tradeable', it.is_tradeable,
            'is_stackable', it.is_stackable,
            'max_stack', it.max_stack,
            'required_level', coalesce(it.required_level, 1),
            'required_class', it.required_class,
            'tolerance_increase', coalesce(it.tolerance_increase, 0),
            'overdose_risk', coalesce(it.overdose_risk, 0),
            'production_building_type', it.production_building_type
        )
    )
    into v_inventory
    from public.inventory inv
    left join public.items it on inv.item_id = it.id
    where inv.user_id = v_user_id;

    -- Return empty array if no items
    if v_inventory is null then
        v_inventory := '[]'::jsonb;
    end if;

    return jsonb_build_object('success', true, 'items', v_inventory);
end;
$$;

-- RPC Function to remove items from inventory
create or replace function public.remove_inventory_item(p_item_id text, p_quantity int default 1)
returns jsonb
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_current_quantity int;
    v_row_id uuid;
begin
    -- Get User ID
    v_user_id := auth.uid();
    if v_user_id is null then
        return jsonb_build_object('success', false, 'error', 'Not authenticated');
    end if;

    -- Validate quantity
    if p_quantity <= 0 then
        return jsonb_build_object('success', false, 'error', 'Quantity must be positive');
    end if;

    -- Find the inventory item and get current quantity
    select inv.row_id, inv.quantity
    into v_row_id, v_current_quantity
    from public.inventory inv
    where inv.user_id = v_user_id
      and inv.item_id = p_item_id
    limit 1;

    -- Check if item exists
    if v_row_id is null then
        return jsonb_build_object('success', false, 'error', 'Item not found in inventory');
    end if;

    -- Check if enough quantity
    if v_current_quantity < p_quantity then
        return jsonb_build_object(
            'success', false, 
            'error', format('Not enough items (have: %s, trying to remove: %s)', v_current_quantity, p_quantity)
        );
    end if;

    -- Remove or update quantity
    if v_current_quantity = p_quantity then
        -- Delete the entire row
        delete from public.inventory
        where row_id = v_row_id
          and user_id = v_user_id;
    else
        -- Decrease quantity
        update public.inventory
        set quantity = quantity - p_quantity,
            updated_at = now()
        where row_id = v_row_id
          and user_id = v_user_id;
    end if;

    return jsonb_build_object(
        'success', true, 
        'item_id', p_item_id,
        'removed_quantity', p_quantity,
        'remaining_quantity', greatest(0, v_current_quantity - p_quantity)
    );
end;
$$;
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
-- Add slot_position support to existing RPC functions
-- Run this after add_slot_position.sql migration

-- 1. Update get_inventory() to include slot_position and order by it
CREATE OR REPLACE FUNCTION public.get_inventory()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid;
    v_inventory jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;

    -- Fetch inventory with slot_position, ordered by position
    SELECT jsonb_agg(
        jsonb_build_object(
            'row_id', inv.row_id,
            'id', inv.item_id,
            'item_id', inv.item_id,
            'quantity', inv.quantity,
            'enhancement_level', COALESCE(inv.enhancement_level, 0),
            'is_equipped', COALESCE(inv.is_equipped, false),
            'equip_slot', inv.equip_slot,
            'obtained_at', inv.obtained_at,
            'is_favorite', COALESCE(inv.is_favorite, false),
            'slot_position', inv.slot_position,  -- NEW
            -- Item definition data
            'name', it.name,
            'description', it.description,
            'icon', it.icon,
            'item_type', it.type,
            'rarity', it.rarity,
            'weapon_type', it.weapon_type,
            'armor_type', it.armor_type,
            'material_type', it.material_type,
            'potion_type', it.potion_type,
            'attack', it.attack,
            'defense', it.defense,
            'health', it.health,
            'power', it.power,
            'energy_restore', it.energy_restore,
            'heal_amount', it.heal_amount,
            'base_price', it.base_price,
            'vendor_sell_price', it.vendor_sell_price,
            'can_enhance', it.can_enhance,
            'max_enhancement', it.max_enhancement,
            'is_tradeable', it.is_tradeable,
            'is_stackable', it.is_stackable,
            'max_stack', it.max_stack,
            'required_level', COALESCE(it.required_level, 1),
            'required_class', it.required_class,
            'tolerance_increase', COALESCE(it.tolerance_increase, 0),
            'overdose_risk', COALESCE(it.overdose_risk, 0),
            'production_building_type', it.production_building_type
        )
        ORDER BY COALESCE(inv.slot_position, 999), inv.obtained_at  -- Sort by position, unassigned last
    )
    INTO v_inventory
    FROM public.inventory inv
    LEFT JOIN public.items it ON inv.item_id = it.id
    WHERE inv.user_id = v_user_id;

    IF v_inventory IS NULL THEN
        v_inventory := '[]'::jsonb;
    END IF;

    RETURN jsonb_build_object('success', true, 'items', v_inventory);
END;
$$;

-- 2. Create RPC to update item positions (for drag-and-drop slot swapping)
CREATE OR REPLACE FUNCTION public.update_item_positions(p_updates jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid;
    v_update jsonb;
    v_row_id uuid;
    v_new_position int;
    v_count int := 0;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- p_updates is array like: [{"row_id": "uuid", "slot_position": 5}, ...]
    FOR v_update IN SELECT * FROM jsonb_array_elements(p_updates)
    LOOP
        v_row_id := (v_update->>'row_id')::uuid;
        v_new_position := (v_update->>'slot_position')::int;
        
        -- Validate position (0-19)
        IF v_new_position < 0 OR v_new_position > 19 THEN
            RETURN jsonb_build_object(
                'success', false, 
                'error', format('Invalid slot_position: %s (must be 0-19)', v_new_position)
            );
        END IF;
        
        -- Update position
        UPDATE public.inventory
        SET slot_position = v_new_position,
            updated_at = NOW()
        WHERE row_id = v_row_id
          AND user_id = v_user_id;
        
        v_count := v_count + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true, 
        'updated_count', v_count
    );
END;
$$;

-- 3. Update add_inventory_item to support slot_position
-- Add slot_position parameter (optional - finds first empty slot if null)
CREATE OR REPLACE FUNCTION public.add_inventory_item_v2(
    item_data jsonb,
    p_slot_position int DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item_id text;
    v_user_id uuid;
    v_quantity int;
    v_new_row jsonb;
    v_is_stackable boolean;
    v_target_position int;
    v_existing_row record;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;

    v_item_id := item_data->>'id';
    IF v_item_id IS NULL OR v_item_id = '' THEN
        RETURN '{"success": false, "error": "item_id is required"}'::jsonb;
    END IF;
    
    v_quantity := public._jsonb_to_int(item_data->'quantity', 1);

    -- Upsert item definition (same as before)
    INSERT INTO public.items (
        id, name, description, icon, type, rarity, equip_slot,
        weapon_type, armor_type, material_type, potion_type,
        attack, defense, health, power, energy_restore, heal_amount,
        base_price, vendor_sell_price, can_enhance, max_enhancement,
        is_tradeable, is_stackable, max_stack,
        required_level, required_class, tolerance_increase, overdose_risk, production_building_type
    ) VALUES (
        v_item_id, item_data->>'name', item_data->>'description', item_data->>'icon',
        item_data->>'item_type', item_data->>'rarity', item_data->>'equip_slot',
        item_data->>'weapon_type', item_data->>'armor_type', item_data->>'material_type', item_data->>'potion_type',
        public._jsonb_to_int(item_data->'attack', 0), public._jsonb_to_int(item_data->'defense', 0),
        public._jsonb_to_int(item_data->'health', 0), public._jsonb_to_int(item_data->'power', 0),
        public._jsonb_to_int(item_data->'energy_restore', 0), public._jsonb_to_int(item_data->'heal_amount', 0),
        public._jsonb_to_int(item_data->'base_price', 0), public._jsonb_to_int(item_data->'vendor_sell_price', 0),
        COALESCE((item_data->>'can_enhance')::boolean, false), public._jsonb_to_int(item_data->'max_enhancement', 0),
        COALESCE((item_data->>'is_tradeable')::boolean, true), COALESCE((item_data->>'is_stackable')::boolean, true),
        public._jsonb_to_int(item_data->'max_stack', 999),
        public._jsonb_to_int(item_data->'required_level', 1), item_data->>'required_class',
        public._jsonb_to_int(item_data->'tolerance_increase', 0), COALESCE((item_data->>'overdose_risk')::numeric, 0),
        item_data->>'production_building_type'
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name, description = EXCLUDED.description, icon = EXCLUDED.icon,
        attack = EXCLUDED.attack, defense = EXCLUDED.defense, health = EXCLUDED.health, power = EXCLUDED.power;

    -- Check if stackable
    SELECT COALESCE(is_stackable, true) INTO v_is_stackable
    FROM public.items WHERE id = v_item_id;

    -- Check for existing item
    SELECT * INTO v_existing_row FROM public.inventory 
    WHERE user_id = v_user_id AND item_id = v_item_id
    LIMIT 1;

    -- If stackable and exists
    IF v_is_stackable AND v_existing_row IS NOT NULL THEN
        -- Check if it has a valid slot
        IF v_existing_row.slot_position IS NULL OR v_existing_row.slot_position < 0 THEN
             -- FIND A SLOT because the existing one is broken/hidden
            SELECT MIN(slot_num) INTO v_target_position
            FROM generate_series(0, 19) slot_num
            WHERE NOT EXISTS (
                SELECT 1 FROM public.inventory 
                WHERE user_id = v_user_id AND slot_position = slot_num
            );
            
            -- If full, we still have to handle it. 
            -- But upgrading an existing NULL item is better than nothing.
            -- If v_target_position is NULL (full), we leave it as NULL (or maybe 0?)
            -- Let's stick to NULL if full, but ideally we assign a slot.
            
            UPDATE public.inventory
            SET quantity = quantity + v_quantity, 
                slot_position = COALESCE(v_target_position, slot_position), -- Update slot if we found one
                updated_at = NOW()
            WHERE row_id = v_existing_row.row_id
            RETURNING to_jsonb(inventory.*) INTO v_new_row;
            
        ELSE
            -- Normal update
            UPDATE public.inventory
            SET quantity = quantity + v_quantity, updated_at = NOW()
            WHERE row_id = v_existing_row.row_id
            RETURNING to_jsonb(inventory.*) INTO v_new_row;
        END IF;

    ELSE
        -- Find slot position (use provided or find first empty)
        IF p_slot_position IS NOT NULL THEN
            v_target_position := p_slot_position;
        ELSE
            -- Find first empty slot (0-19)
            SELECT MIN(slot_num) INTO v_target_position
            FROM generate_series(0, 19) slot_num
            WHERE NOT EXISTS (
                SELECT 1 FROM public.inventory 
                WHERE user_id = v_user_id AND slot_position = slot_num
            );
        END IF;
        
        -- If inventory is full (v_target_position IS NULL)
        IF v_target_position IS NULL THEN
             RETURN '{"success": false, "error": "Inventory is full"}'::jsonb;
        END IF;

        -- Insert new item
        INSERT INTO public.inventory (
            user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position
        ) VALUES (
            v_user_id, v_item_id, v_quantity,
            public._jsonb_to_int(item_data->'enhancement_level', 0),
            false, EXTRACT(EPOCH FROM NOW())::bigint, v_target_position
        )
        RETURNING to_jsonb(inventory.*) INTO v_new_row;
    END IF;

    RETURN jsonb_build_object('success', true, 'data', v_new_row);
END;
$$;
-- Supabase SQL Functions for Hospital System
-- Run this in Supabase SQL Editor

-- Function: get_hospital_status
-- Fetches current hospital status for a user
CREATE OR REPLACE FUNCTION public.get_hospital_status(p_auth_id UUID)
RETURNS TABLE(
  in_hospital BOOLEAN,
  release_time BIGINT,
  hospital_reason TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(u.hospital_until > NOW(), FALSE),
    EXTRACT(EPOCH FROM u.hospital_until)::BIGINT,
    u.hospital_reason
  FROM public.users u
  WHERE u.auth_id = p_auth_id
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: admit_to_hospital
-- Admits a user to hospital (server-side)
CREATE OR REPLACE FUNCTION public.admit_to_hospital(
  p_auth_id UUID,
  p_duration_minutes INT,
  p_reason TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  hospital_until TIMESTAMP,
  release_time BIGINT
) AS $$
DECLARE
  v_release_time TIMESTAMP;
BEGIN
  v_release_time := NOW() + (p_duration_minutes || ' minutes')::INTERVAL;
  
  UPDATE public.users
  SET 
    hospital_until = v_release_time,
    hospital_reason = p_reason,
    updated_at = NOW()
  WHERE auth_id = p_auth_id;
  
  RETURN QUERY
  SELECT 
    TRUE,
    v_release_time,
    EXTRACT(EPOCH FROM v_release_time)::BIGINT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: release_from_hospital
-- Releases a user from hospital
CREATE OR REPLACE FUNCTION public.release_from_hospital(
  p_auth_id UUID,
  p_method TEXT,
  p_cost INT DEFAULT 0
)
RETURNS TABLE(
  success BOOLEAN,
  new_gems INT
) AS $$
DECLARE
  v_current_gems INT;
BEGIN
  -- Get current gems
  SELECT gems INTO v_current_gems
  FROM public.users
  WHERE auth_id = p_auth_id;
  
  -- Check if player has enough gems
  IF p_method = 'gems' AND v_current_gems < p_cost THEN
    RETURN QUERY SELECT FALSE, v_current_gems;
    RETURN;
  END IF;
  
  -- Update user
  UPDATE public.users
  SET 
    hospital_until = NULL,
    hospital_reason = NULL,
    gems = CASE WHEN p_method = 'gems' THEN gems - p_cost ELSE gems END,
    updated_at = NOW()
  WHERE auth_id = p_auth_id;
  
  -- Return success with new gems count
  SELECT gems INTO v_current_gems
  FROM public.users
  WHERE auth_id = p_auth_id;
  
  RETURN QUERY SELECT TRUE, v_current_gems;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
