# CRITICAL FIX: Deploy New Recipes RPC to Supabase

## Problem
The recipes query is using wrong column name `facility_level_required` which doesn't exist in the database. The correct column is `required_level`.

## Solution
Created a new PostgreSQL RPC function that uses the correct column names. You need to deploy it to Supabase immediately.

## Deployment Instructions

### Option 1: Supabase Dashboard (RECOMMENDED)
1. Go to: https://supabase.com/dashboard/project/znvsyzstmxhqvdkkmgdt/sql/new
2. Copy the SQL content from:  `c:\Users\selçuk\Documents\gkk\database\migrations\create_get_facility_recipes_rpc.sql`
3. Paste it into the SQL editor
4. Click "RUN" button
5. You should see: "CREATE FUNCTION" message (green success)

### Option 2: Using Database Sync
```bash
cd "c:\Users\selçuk\Documents\gkk"
supabase push --linked --project-ref znvsyzstmxhqvdkkmgdt
```

### Option 3: Manual via psql
```powershell
$env:PGPASSWORD = "your_db_password"
psql -h db.znvsyzstmxhqvdkkmgdt.supabase.co -U postgres -d postgres -c "$(Get-Content database\migrations\create_get_facility_recipes_rpc.sql -Raw)"
```

## What Changed in Code

### FacilityManager.gd
- Line 283-310: Updated `get_facility_recipes()` to call new RPC instead of Edge Function
- Changed endpoint from: `/functions/v1/get_facility_recipes` (Edge Function with bug)
- Changed to: `/rest/v1/rpc/get_facility_recipes_rpc` (Direct RPC call with fixed column names)

### New RPC Function
- File: `database/migrations/create_get_facility_recipes_rpc.sql`
- Name: `get_facility_recipes_rpc(p_facility_type TEXT)`
- Returns: `{success, recipes, count, facility_type}`
- Uses: `required_level` (CORRECT column name)

## Testing After Deployment

1. Restart Godot game
2. Navigate to: Facilities screen
3. Click on any facility (e.g., Mine)
4. Open Crafting/Recipes section
5. Should see recipes load WITHOUT `facility_level_required does not exist` error

## Expected Results
- ✅ Recipes load successfully
- ✅ No database column errors
- ✅ Production queue displays (already fixed)
- ✅ Game runs without errors

## Rollback Plan
If something goes wrong:
```sql
DROP FUNCTION IF EXISTS get_facility_recipes_rpc(TEXT);
```

Then go back to using Edge Function (but it also has the bug).

## Timeline
1. Deploy RPC: ~1 minute
2. Restart game: ~30 seconds
3. Test: ~2 minutes
Total: ~3.5 minutes

---

**DEPLOY THIS RPC NOW!** Without it, recipes will not load and the error will persist.
