-- ============================================
-- ENSURE ITEMS TABLE HAS ALL REQUIRED COLUMNS
-- ============================================
-- This script ensures the items table has all columns needed by ItemDatabase.gd
-- It is safe to run multiple times (uses IF NOT EXISTS)

-- Add missing columns for all item types
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS id text PRIMARY KEY;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS name text NOT NULL;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS type text NOT NULL;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rarity text NOT NULL DEFAULT 'COMMON';
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS icon text;

-- Sub-types
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS weapon_type text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS armor_type text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS material_type text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS potion_type text;

-- Equipment slots
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS equip_slot text;

-- Stats
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS attack int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS defense int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS health int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS power int DEFAULT 0;

-- Enhancement
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS can_enhance boolean DEFAULT false;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS max_enhancement int DEFAULT 0;

-- Requirements
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS required_level int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS required_class text;

-- Economy
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS base_price int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS vendor_sell_price int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS is_tradeable boolean DEFAULT true;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS is_stackable boolean DEFAULT false;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS max_stack int DEFAULT 1;

-- Potion effects
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS energy_restore int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS health_restore int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS mana_restore int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS tolerance_increase int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS overdose_risk double precision DEFAULT 0.0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS buff_duration int DEFAULT 0;

-- Production/Crafting
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS production_building_type text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS production_rate_per_hour int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS production_required_level int DEFAULT 0;

-- Recipe system
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_requirements jsonb DEFAULT '{}'::jsonb;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_result_item_id text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_building_type text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_production_time int DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_required_level int DEFAULT 0;

-- Rune system
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_enhancement_type text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_success_bonus double precision DEFAULT 0.0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_destruction_reduction double precision DEFAULT 0.0;

-- Cosmetic system
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS cosmetic_effect text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS cosmetic_bind_on_pickup boolean DEFAULT false;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS cosmetic_showcase_only boolean DEFAULT false;

-- Timestamps
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT NOW();
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS updated_at timestamp DEFAULT NOW();

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_items_type ON public.items(type);
CREATE INDEX IF NOT EXISTS idx_items_rarity ON public.items(rarity);
CREATE INDEX IF NOT EXISTS idx_items_required_level ON public.items(required_level);
CREATE INDEX IF NOT EXISTS idx_items_equip_slot ON public.items(equip_slot);
CREATE INDEX IF NOT EXISTS idx_items_production_building_type ON public.items(production_building_type);
