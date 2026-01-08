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
    
    -- If player already has this item, increase quantity (unless it's non-stackable unique like equipment, but for now we stack)
    -- Start simple: Insert or Update quantity
    if exists (select 1 from public.inventory where user_id = v_user_id and item_id = v_item_id) then
        update public.inventory
        set quantity = quantity + v_quantity,
            updated_at = now()
        where user_id = v_user_id and item_id = v_item_id
        returning to_jsonb(inventory.*) into v_new_row;
    else
        -- Insert new item
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
