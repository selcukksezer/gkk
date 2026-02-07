# Database Restoration Guide

## Overview

This document describes the complete database restoration process after a database deletion. The restoration ensures all items, facility recipes, and game systems from the Godot game code (specifically `core/data/ItemDatabase.gd`) are properly synced with the database.

## What Was Restored

### Items (39 total)
All items from `core/data/ItemDatabase.gd` have been added to the `items` table:

#### Weapons (6 items)
- `weapon_sword_basic` - Demir Kılıç (Basic Iron Sword)
- `weapon_bow_elven` - Elf Yayı (Elven Bow) 
- `weapon_custom_longsword` - Eşsiz Uzun Kılıç (Custom Longsword)
- `weapon_iron_sword` - Demir Kılıç
- `weapon_steel_sword` - Çelik Kılıç (Steel Sword)
- `weapon_legendary_sword` - Efsanevi Kılıç (Legendary Sword)

#### Armor (5 items)
- `armor_custom_plate` - Eşsiz Zırh (Custom Plate Armor)
- `armor_chest_leather` - Deri Göğüslük (Leather Chest)
- `armor_chest_plate` - Plaka Göğüslük (Plate Chest)
- `armor_leather_armor` - Deri Zırh (Leather Armor)
- `armor_chain_mail` - Zincir Zırh (Chain Mail)
- `armor_plate_armor` - Plaka Zırh (Plate Armor)

#### Potions (5 items)
- `potion_energy_minor` - Minör Enerji İksiri (Energy +20)
- `potion_antidote` - Antidot (Removes addiction)
- `potion_health` - Sağlık İksiri (Health Potion)
- `potion_mana` - Mana İksiri (Mana Potion)
- `potion_stamina` - Dayanıklılık İksiri (Stamina buff, 1 hour)

#### Materials - Ore (6 items)
- `material_iron_ore` - Demir Cevheri
- `material_copper_ore` - Bakır Cevheri
- `material_gold_ore` - Altın Cevheri (requires level 5)
- `material_silver_ore` - Gümüş Cevheri (requires level 3)
- `material_crystal` - Kristal (requires level 7)
- `material_diamond` - Elmas (requires level 10)

#### Materials - Wood (3 items)
- `material_wood` - Kereste
- `material_hardwood` - Sert Kereste (requires level 4)
- `material_bamboo` - Bambu (requires level 3)

#### Materials - Leather & Textiles (3 items)
- `material_leather` - Deri
- `material_quality_leather` - Kaliteli Deri (requires level 5)
- `material_wool` - Yün

#### Materials - Herbs (3 items)
- `material_herb` - Tıbbi Ot
- `material_rare_herb` - Nadir Ot (requires level 5)
- `material_dragon_blood` - Ejderhain Kanı (requires level 10)

#### Upgrade Scrolls (3 items)
- `scroll_upgrade_low` - Düşük Sınıf Yükseltme Kağıdı (for COMMON/UNCOMMON)
- `scroll_upgrade_middle` - Orta Sınıf Yükseltme Kağıdı (for RARE/EPIC)
- `scroll_upgrade_high` - Yüksek Sınıf Yükseltme Kağıdı (for LEGENDARY/MYTHIC)

#### Runes (5 items)
- `rune_attack_minor` - Küçük Saldırı Rünü (+5% success)
- `rune_defense_minor` - Küçük Savunma Rünü (+5% success)
- `rune_attack_major` - Büyük Saldırı Rünü (+10% success)
- `rune_defense_major` - Büyük Savunma Rünü (+10% success)
- `rune_legendary` - Efsanevi Rüne (+15% success)

#### Gems (3 items)
- `gem_ruby` - Yakut (attack +10)
- `gem_sapphire` - Safir (defense +15)
- `gem_emerald` - Zümrüt (health +50)

#### Cosmetics (1 item)
- `cosmetic_crown_gold` - Altın Taç

#### Recipes (1 item)
- `recipe_sword_basic` - Demir Kılıç Tarifi

### Facility Recipes

Comprehensive recipes have been added for all facility types:

1. **Mining** (`mine`, `mining`) - Produces: iron_ore, copper_ore, silver_ore, gold_ore, crystal, diamond
2. **Sawmill/Lumber Mill** (`sawmill`, `lumber_mill`) - Produces: wood, bamboo, hardwood
3. **Farm** (`farm`, `farming`) - Produces: leather, wool, quality_leather
4. **Herb Garden** (`herb_garden`) - Produces: herb, rare_herb, dragon_blood
5. **Alchemy Lab** (`alchemy_lab`) - Produces: potions (energy, antidote, health, mana, stamina)
6. **Blacksmith** (`blacksmith`) - Produces: weapons (iron_sword, steel_sword, legendary_sword)
7. **Armorer** (`armorer`) - Produces: armor (leather_armor, chain_mail, plate_armor)
8. **Runesmith** (`runesmith`) - Produces: runes (all types)
9. **Gem Cutter** (`gem_cutter`) - Produces: gems (ruby, sapphire, emerald)
10. **Scroll Library** (`scroll_library`) - Produces: upgrade scrolls (low, middle, high)

## Restoration Scripts

The following SQL scripts are provided in `database/migrations/`:

### 1. `00_COMPLETE_RESTORE.sql` (MAIN SCRIPT)
**Purpose:** Single comprehensive script that runs everything in order  
**Use:** Run this first - it calls the other scripts automatically  
**What it does:**
- Ensures items table has all required columns
- Creates facility_recipes table
- Creates all necessary indexes
- Imports all items from ItemDatabase.gd
- Imports all facility recipes
- Provides verification queries

### 2. `ensure_items_table_columns.sql`
**Purpose:** Ensures items table has all required columns  
**Safe to run:** Yes, uses `IF NOT EXISTS`  
**Columns added:** 40+ columns including weapon_type, armor_type, rune_success_bonus, cosmetic_effect, etc.

### 3. `restore_itemdatabase_items.sql`
**Purpose:** Adds all 39 items from ItemDatabase.gd  
**Safe to run:** Yes, uses `ON CONFLICT DO UPDATE`  
**Items:** All weapons, armor, potions, materials, scrolls, runes, gems, cosmetics, recipes

### 4. `restore_facility_recipes.sql`
**Purpose:** Adds comprehensive facility recipes  
**Safe to run:** Yes, uses `ON CONFLICT DO UPDATE`  
**Recipes:** 60+ recipes for 10 facility types

## How to Restore

### Option 1: Complete Restoration (Recommended)
```bash
# Run all three scripts in order
cd /path/to/gkk

# Step 1: Ensure table structure
psql -U postgres -d your_database -f database/migrations/ensure_items_table_columns.sql

# Step 2: Restore items
psql -U postgres -d your_database -f database/migrations/restore_itemdatabase_items.sql

# Step 3: Restore facility recipes
psql -U postgres -d your_database -f database/migrations/restore_facility_recipes.sql
```

### Option 2: Individual Scripts
Run each script separately if you need more control or if one step fails.
```bash
# Step 1: Ensure table structure
psql -U postgres -d your_database -f database/migrations/ensure_items_table_columns.sql

# Step 2: Restore items
psql -U postgres -d your_database -f database/migrations/restore_itemdatabase_items.sql

# Step 3: Restore facility recipes
psql -U postgres -d your_database -f database/migrations/restore_facility_recipes.sql
```

### Option 3: Via Supabase CLI
```bash
supabase db push --include-all
```

## Verification

After running the restoration, verify the data:

```sql
-- Check total items
SELECT COUNT(*) FROM public.items;
-- Expected: 39+ items

-- Check items by type
SELECT type, COUNT(*) 
FROM public.items 
GROUP BY type 
ORDER BY type;

-- Check facility recipes
SELECT COUNT(*) FROM public.facility_recipes;
-- Expected: 60+ recipes

-- Check recipes by facility type
SELECT facility_type, COUNT(*) 
FROM public.facility_recipes 
GROUP BY facility_type 
ORDER BY facility_type;

-- Verify specific item exists
SELECT id, name, type, rarity, base_price 
FROM public.items 
WHERE id = 'weapon_sword_basic';

-- Verify facility recipe exists
SELECT id, facility_type, output_item_id, duration_seconds 
FROM public.facility_recipes 
WHERE facility_type = 'mine';
```

## Item ID Consistency

⚠️ **CRITICAL:** All item IDs must match exactly between:
1. `core/data/ItemDatabase.gd` (game code)
2. `public.items` table (database)
3. `facility_recipes.output_item_id` (database)

Any mismatch will cause sync errors in the game.

## Database Schema

### Items Table Columns
- **Identity:** id (PK), name, description, type, rarity, icon
- **Sub-types:** weapon_type, armor_type, material_type, potion_type
- **Stats:** attack, defense, health, power
- **Enhancement:** can_enhance, max_enhancement
- **Economy:** base_price, vendor_sell_price, is_tradeable, is_stackable, max_stack
- **Requirements:** required_level, required_class, equip_slot
- **Potion Effects:** energy_restore, health_restore, mana_restore, tolerance_increase, buff_duration
- **Production:** production_building_type, production_rate_per_hour, production_required_level
- **Recipes:** recipe_requirements, recipe_result_item_id, recipe_building_type
- **Runes:** rune_enhancement_type, rune_success_bonus, rune_destruction_reduction
- **Cosmetics:** cosmetic_effect, cosmetic_bind_on_pickup, cosmetic_showcase_only

### Facility Recipes Table Columns
- **Identity:** id (PK), facility_type
- **Output:** output_item_id, output_quantity
- **Input:** input_materials (JSONB), gold_cost
- **Time:** duration_seconds
- **Requirements:** required_level
- **Mechanics:** success_rate, base_suspicion_increase

## Notes

1. **Safe to Re-run:** All scripts use `ON CONFLICT DO UPDATE` or `IF NOT EXISTS`, so they're safe to run multiple times
2. **No Data Loss:** The scripts only add/update data, never delete
3. **Idempotent:** Running the scripts multiple times produces the same result
4. **Order Matters:** If running individually, follow the order: columns → items → recipes
5. **Supabase Compatible:** All scripts work with Supabase PostgreSQL

## Troubleshooting

### "relation 'items' does not exist"
Run `ensure_items_table_columns.sql` first to create the table

### "column 'X' does not exist"
Run `ensure_items_table_columns.sql` to add missing columns

### Items not appearing in game
1. Verify item IDs match between ItemDatabase.gd and database
2. Check that items table has all required columns
3. Verify game is connecting to the correct database

### Facility recipes not working
1. Check that facility_recipes table exists
2. Verify output_item_id references valid items in items table
3. Check facility_type matches the game code

## Future Maintenance

When adding new items to ItemDatabase.gd:
1. Add the item definition to the game code
2. Run `restore_itemdatabase_items.sql` or add manual INSERT
3. If it's produced by a facility, add a recipe to `restore_facility_recipes.sql`
4. Ensure item IDs match exactly

## Contact

For issues or questions about database restoration, refer to:
- Game design document: `GOLGE-KRALLIK-MASTER-GDD.md`
- Production system docs: `PRODUCTION_SYSTEM_FIX_REPORT.md`
- Facility setup: `FACILITY_FIX_NOTES.md`
