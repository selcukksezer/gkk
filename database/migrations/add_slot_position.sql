-- Migration: Add slot_position to inventory table
-- Purpose: Enable manual inventory slot positioning (0-19)
-- Date: 2026-01-12

-- 1. Add slot_position column
ALTER TABLE inventory 
ADD COLUMN IF NOT EXISTS slot_position INTEGER;

-- 2. Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_inventory_slot_position 
ON inventory(user_id, slot_position);

-- 3. Initialize existing items with sequential positions
-- Assign positions 0,1,2... based on obtained_at (oldest first)
UPDATE inventory 
SET slot_position = subq.row_num - 1
FROM (
  SELECT 
    row_id,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY obtained_at) as row_num
  FROM inventory
  WHERE slot_position IS NULL
) subq
WHERE inventory.row_id = subq.row_id;

-- 4. Verify migration
-- SELECT user_id, item_id, slot_position, obtained_at 
-- FROM inventory 
-- WHERE user_id = 'YOUR_USER_ID'
-- ORDER BY slot_position;
