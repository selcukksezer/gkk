# Database Restoration Scripts

This directory contains SQL migration scripts to restore the database after deletion.

## Quick Start

Run these 3 scripts in order:

```bash
# 1. Ensure table structure (44 columns)
psql -U postgres -d your_database -f ensure_items_table_columns.sql

# 2. Restore all items (39 items)
psql -U postgres -d your_database -f restore_itemdatabase_items.sql

# 3. Restore facility recipes (60+ recipes)
psql -U postgres -d your_database -f restore_facility_recipes.sql
```

## What Gets Restored

- **39 Items**: Weapons, armor, potions, materials, scrolls, runes, gems, cosmetics
- **60+ Recipes**: Production recipes for 10 facility types (mining, farming, alchemy, etc.)
- **44 Columns**: Complete items table schema
- **10 Facility Types**: All production systems configured

## Files

### Core Restoration Scripts

1. **`ensure_items_table_columns.sql`** (5KB)
   - Creates/updates items table with 44 columns
   - Safe to run multiple times (uses IF NOT EXISTS)
   - Creates performance indexes

2. **`restore_itemdatabase_items.sql`** (21KB)
   - Inserts all 39 items from ItemDatabase.gd
   - Uses ON CONFLICT DO UPDATE (safe to re-run)
   - Exact ID matching with game code

3. **`restore_facility_recipes.sql`** (18KB)
   - Inserts 60+ production recipes
   - Covers all 10 facility types
   - Configures production parameters

4. **`00_COMPLETE_RESTORE.sql`** (9KB)
   - Master script (currently simplified)
   - Includes verification queries
   - Shows restoration status

### Other Migrations

The directory also contains 50+ other migration files for various game systems:
- Inventory and equipment system
- Facilities and production queues
- Market and trading system
- Prison and hospital systems
- Enhancement and crafting systems

These were created earlier and may have already been applied to your database.

## Documentation

See the root directory for comprehensive guides:
- **`DATABASE_RESTORATION_GUIDE.md`** - Complete English guide
- **`HIZLI_BASLANGIC.md`** - Turkish quick-start guide
- **`RESTORATION_TECHNICAL_SUMMARY.md`** - Technical reference
- **`TASK_COMPLETION_SUMMARY.md`** - Task overview

## Verification

After running the scripts, verify the restoration:

```sql
-- Check items were added
SELECT COUNT(*) FROM public.items;
-- Expected: 39 or more

-- Check item types
SELECT type, COUNT(*) as count 
FROM public.items 
GROUP BY type 
ORDER BY type;

-- Check facility recipes
SELECT COUNT(*) FROM public.facility_recipes;
-- Expected: 60 or more

-- Check facility types
SELECT facility_type, COUNT(*) as recipe_count
FROM public.facility_recipes
GROUP BY facility_type
ORDER BY facility_type;
```

## Safety Features

- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Non-destructive**: Only adds/updates, never deletes
- ✅ **No downtime**: Can run on live database
- ✅ **Transaction-safe**: Can wrap in BEGIN/ROLLBACK
- ✅ **Conflict handling**: Uses ON CONFLICT DO UPDATE

## Troubleshooting

### "relation 'items' does not exist"
Run the 5 base SQL files first from `supabase/sql/`:
- 01_create_inventory_table.sql
- 02_normalize_and_rpc.sql
- 03_equipment_system.sql
- 04_slot_position_rpcs.sql
- hospital_functions.sql

### "column does not exist"
Run `ensure_items_table_columns.sql` to add missing columns

### Items not appearing in game
1. Verify item IDs match between database and ItemDatabase.gd
2. Check database connection in game
3. Restart the game

## Order of Execution

If running all migrations from scratch:

1. **Base Schema** (5 files from supabase/sql/)
2. **Items Table Structure** (`ensure_items_table_columns.sql`)
3. **Items Data** (`restore_itemdatabase_items.sql`)
4. **Facility Recipes** (`restore_facility_recipes.sql`)
5. **Optional**: Other system-specific migrations as needed

## Notes

- All item IDs match exactly between ItemDatabase.gd and database
- Scripts are safe to run even if data already exists
- Each script includes inline documentation
- Indexes are created automatically for performance

## Support

For detailed information, see the documentation files in the root directory.
