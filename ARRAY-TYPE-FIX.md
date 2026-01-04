# Array Type Assignment Fix

## Issue
```
Invalid assignment of property or key 'loot' with value of type 'Array' 
on a base object of type 'RefCounted (DungeonInstance)'
```

## Root Cause
`DungeonInstance.loot` is strictly typed as `Array[String]`, but code was assigning generic `Array` or untyped array literals.

## Solution

### Before (WRONG)
```gdscript
dungeon_instance.loot = loot  # Generic Array
dungeon_instance.loot = ["steel_sword", "iron_armor"]  # Array literal without type
```

### After (CORRECT)
```gdscript
# Convert to typed array
var loot_items: Array[String] = []
if typeof(loot) == TYPE_ARRAY:
    for item in loot:
        loot_items.append(str(item))
dungeon_instance.loot = loot_items

# Or use typed literal
var test_loot: Array[String] = ["steel_sword", "iron_armor"]
dungeon_instance.loot = test_loot
```

## Fixed Locations

| File | Line | Issue | Fix |
|------|------|-------|-----|
| DungeonBattleScreen.gd | 178-183 | Direct Array assignment | Loop through and convert to Array[String] |
| DungeonBattleScreen.gd | 482 | Array literal without type | Added explicit `Array[String]` type annotation |

## Key Principle

**In GDScript 4.0+, typed arrays are strict:**
- `Array[String]` only accepts string items
- Cannot assign generic `Array` to `Array[String]`
- Must explicitly convert or declare with proper type

## Verification

All files now pass compilation:
- ✅ DungeonBattleScreen.gd
- ✅ DungeonManager.gd  
- ✅ DungeonInstance.gd

Ready for runtime testing!
