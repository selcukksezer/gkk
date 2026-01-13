-- Migration: Enforce Unique Inventory Slots
-- Prevents multiple items from occupying the same slot_position for a single user.

-- 1. First, make sure we ignore equipped items (since they use equip_slot, slot_position should be ignored or NULL)
-- Ideally, equipped items have slot_position = NULL.
-- But if they have stale values, we should ignore them in this constraint if possible, 
-- or better, ensure equipped items always have NULL slot_position.

-- Let's clean up equipped items first just in case
UPDATE public.inventory
SET slot_position = NULL
WHERE is_equipped = TRUE AND slot_position IS NOT NULL;

-- 2. Create Unique Index
-- We use a Partial Index to only enforce uniqueness on items that actually have a slot position.
-- This allows multiple items to have NULL slot_position (e.g. equipped items, overflow items).

DROP INDEX IF EXISTS idx_inventory_user_slot_unique;

CREATE UNIQUE INDEX idx_inventory_user_slot_unique 
ON public.inventory (user_id, slot_position)
WHERE slot_position IS NOT NULL;

-- This will fail immediately if there are duplicates remaining.
-- So 'repair_inventory_slots.sql' MUST be run (and called) before this migration is applied effectively.
