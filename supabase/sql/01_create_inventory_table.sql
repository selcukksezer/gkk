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
