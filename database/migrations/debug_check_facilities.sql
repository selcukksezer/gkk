-- DEBUG SCRIPT: Check Facilities and Force Visibility

-- 1. Temporarily Disable RLS to specific isolate the issue
ALTER TABLE public.facilities DISABLE ROW LEVEL SECURITY;

-- 2. Select all facilities to see if ANY exist
SELECT * FROM public.facilities;

-- 3. Check if user has gold (just to verify user ID lookup)
SELECT id, email, role FROM auth.users LIMIT 5;
SELECT * FROM game.users LIMIT 5;

-- NOTE: If you see rows in 'facilities' after running this, 
-- it means the Client (Godot) is using the Wrong ID or Filter.
-- If 'facilities' is EMPTY, then the 'Unlock' RPC is failing to save even though it says success.
