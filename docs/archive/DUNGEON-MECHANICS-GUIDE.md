# Dungeon Mechanics Improvement Guide

## Fixed Issues ✅

### Parser Errors
1. **C-style ternary operators** - GDScript doesn't support `condition ? true : false` syntax
   - Fixed: Replaced with `value if condition else other` syntax
   - File: `DungeonBattleScreen.gd` line 232-233

2. **Integer division warnings** - Floating point result discarded
   - Fixed: Used explicit float conversion `Time.get_ticks_msec() / 1000.0` → wrapped in `int()`
   - Files: `DungeonInstance.gd`, `DungeonManager.gd`

3. **Shadowed built-in function** - Variable name `range` conflicts with built-in
   - Fixed: Renamed to `reward_range` for clarity

4. **Unused parameters** - Functions that don't use all parameters
   - Fixed: Prefixed unused parameters with underscore (`_player_data`)

---

## Dungeon Mechanics Architecture

### 1. Success Rate Calculation (`_calculate_success_rate`)

The success rate is a **balanced formula** that incorporates:

```
Success Rate = Base Rate + Bonuses - Penalties
             = base_rate + gear_bonus + skill_bonus + level_bonus - difficulty_penalty - danger_penalty - level_penalty
```

#### Components:

**Base Rate by Difficulty:**
- EASY: 85%
- MEDIUM: 70%
- HARD: 55%
- DUNGEON (Solo): 45%

**Gear Factor (Equipment Power)**
```
Gear Score = (Weapon Power + Armor Defense) / 300.0
- Max weapon: 150 power (60 base + 90 rarity bonus)
- Max armor: 150 defense (60 base + 90 rarity bonus)
- Effect on success: ±25% (GEAR_WEIGHT = 0.25)
```

**Level Factor (Character Power)**
```
Level Advantage = Character Level - Required Level
Level Score = clamp(Level Advantage / 50.0, -1.0, 1.0)
- +50 level advantage = +25% success (LEVEL_WEIGHT = 0.25)
- -50 level deficiency = heavy penalty (8% per level)
```

**Difficulty/Danger Factor**
```
Difficulty Penalty = danger_level / 100.0
- danger_level ranges 0-100
- Effect: -20% to -15% (DIFFICULTY_WEIGHT + DANGER_WEIGHT)
```

**Skill Factor**
```
Skill Score = 0.2 (currently placeholder)
- Future: Read from PlayerData.skill_points
- Effect: +3% (SKILL_WEIGHT = 0.15)
```

#### Weight Distribution:
| Factor | Weight | Max Effect |
|--------|--------|-----------|
| Gear | 25% | +25% |
| Skill | 15% | +3% |
| Level | 15% | ±15% |
| Difficulty | 20% | -20% |
| Danger | 15% | -12% |
| Level Penalty | - | -40% (if underleveled) |

#### Example Calculation:
```
Player: Level 15, Weapon 80 power, Armor 70 defense
Dungeon: HARD (55%), Required 20, Danger 60

Gear: (80+70)/300 = 0.5 → +12.5%
Level: (15-20)/50 = -0.1 → -1.5%
Level Penalty: (20-15)*0.08 = -40%
Difficulty: 60/100 = -12%

Final = 55% + 12.5% - 1.5% - 40% - 12% = 14% success
        (Higher risk, low level, needs gear upgrades)
```

---

### 2. Hospitalization Risk

Failure doesn't always mean just losing the dungeon—there's a risk of **injury** (hospitalization).

**Hospitalization Rates by Difficulty:**
| Difficulty | Rate | Duration |
|-----------|------|----------|
| EASY | 0% | - |
| MEDIUM | 5% | 1-2 min |
| HARD | 15% | 2-4 min |
| DUNGEON | 25% | 4-10 min |

**Mechanic:**
- Only applies on **failure**
- Prevents dungeon/activities temporarily
- Duration scales with difficulty
- Equipment quality doesn't affect rate (but should reduce via success rate increase)

---

### 3. Reward System

#### Success Rewards

**Base Gold Range:** Defined per dungeon (e.g., 100-500 gold)

**Multiplier Formula:**
```
Final Range = Base Range × (Danger × Gear × Level × Season)

Danger Multiplier = 1.0 + (danger_level / 100.0) × 0.5
Gear Multiplier = 1.0 + (gear_score × 0.2)
Level Multiplier = max(0.5, 1.0 - level_penalty)  # 50% min
Season Multiplier = 1.0 to 2.0 (from Config events)
```

**Critical Success Bonus:** 10% chance → +50% gold

**Example:**
```
Base: 100-500 gold
Danger (60): ×1.30
Gear (0.5): ×1.10
Level (underleveled): ×0.75
Season (holiday): ×1.5

Final Range: 100×1.30×1.10×0.75×1.5 to 500×1.30×1.10×0.75×1.5
           = 160 to 810 gold
```

#### Failure Rewards
- 35% of base success gold
- No loot
- Same season multiplier applies

---

## Code Organization

### DungeonManager.gd
Main controller for dungeon lifecycle:

```gdscript
# 1. Start dungeon
start_dungeon(dungeon_def, player_data) → instance

# 2. Calculate success rate
_calculate_success_rate(dungeon_def, player_data) → float

# 3. Resolve (roll RNG)
resolve_dungeon(instance_id, player_data) → result

# 4. Apply rewards
_calculate_success_rewards(instance, player_data)
_calculate_failure_rewards(instance, player_data)

# 5. Hospitalization check
_should_hospitalize(instance) → bool
_apply_hospitalization(instance)

# 6. Loot generation
_generate_loot(dungeon_id) → Array[String]

# Utilities
preview_success_rate(dungeon_def, player_data) → breakdown
compute_reward_range(dungeon_def, player_data) → min/max
estimate_reward_range(dungeon_def) → UI preview
```

### DungeonInstance.gd
Data class for single dungeon run:
- `success_rate_calculated` - Computed at start
- `success_roll` - Random value [0, 1)
- `actual_success` - Roll < calculated rate?
- `rewards` - Gold/exp earned
- `loot` - Items dropped
- `is_hospitalized` - Injury status
- `hospital_duration_minutes` - Recovery time

---

## UI Integration Points

### DungeonScreen.gd
Shows available dungeons:
```gdscript
# Display estimated rewards on card
estimated = dungeon_manager.estimate_reward_range(dungeon_def)
# Show: "💰 160-810 altın (x1.5)" if season bonus active

# Info button opens modal showing:
- Base rewards
- Season multiplier breakdown
- Top loot items
- Estimated range after all modifiers
```

### DungeonBattleScreen.gd
Shows battle result:
```gdscript
# On success:
var reward_range = compute_reward_range_from_instance(instance, player_data)
var gold = randi_range(reward_range.min_gold, reward_range.max_gold)
# Roll 10% critical success → gold × 1.5

# Telemetry tracks:
- calculated_success (what formula predicted)
- actual_success (RNG result)
- rewards (gold/exp earned)
- loot_count
- hospitalized (yes/no)
```

---

## Balancing Knobs

### To make dungeons easier:
1. ↓ Base difficulty rates (BASE_SUCCESS_RATES)
2. ↑ GEAR_WEIGHT (gear matters more)
3. ↓ DIFFICULTY_WEIGHT (penalties softer)
4. ↑ Base rewards (min/max gold)

### To make dungeons riskier:
1. ↑ DANGER_WEIGHT (higher risk multiplier)
2. ↑ HOSPITALIZE_RATES (more injuries)
3. ↑ HOSPITAL_DURATION_RANGE (longer recovery)
4. ↓ Level multiplier minimum (underleveled gets wrecked)

### To make gear matter more:
1. ↑ GEAR_WEIGHT (0.25 → 0.35)
2. ↑ GEAR_REWARD_WEIGHT (0.2 → 0.3)
3. Increase rarity bonus in gear (20 → 50 power/defense)

---

## Telemetry Events

All dungeon events are tracked:

```gdscript
# On start
Telemetry.track_event("combat.dungeon", "started", {
    user_id, dungeon_id, difficulty, calculated_success
})

# On complete
Telemetry.track_event("combat.dungeon", "completed", {
    user_id, dungeon_id, calculated_success, actual_success,
    rewards, loot_count, duration, hospitalized
})

# On claim rewards
Telemetry.track_event("combat.dungeon", "rewards_claimed", {
    user_id, dungeon_id, gold_earned, exp_earned, items
})
```

---

## Future Improvements

1. **Skill Tree Integration**
   - Read `player_data.skill_tree` to compute dynamic skill_score
   - Example: "Sword Master" skill → +15% success with swords

2. **Buff/Debuff System**
   - Apply temporary bonuses/penalties
   - Example: Potion of Strength +10% to gear score

3. **Group Dungeons**
   - GROUP_SUCCESS_MODIFIER applies to parties
   - Split rewards among players

4. **Difficulty Scaling**
   - danger_level adjusts based on party composition
   - Underleveled players get higher danger multiplier

5. **Loot Rarity**
   - Tie loot drops to success rate
   - Higher difficulty = rarer drops
   - Higher gear = better drop chance

6. **Boss Encounters**
   - Multi-phase boss fights
   - Success rate recalculated per phase
   - Cumulative rewards/injuries

---

## Testing

Run these tests to validate mechanics:

```bash
# Unit tests
godot --headless --script=tests/test_dungeon_preview.gd
godot --headless --script=tests/test_dungeon_rewards_consistency.gd

# Integration test (manual)
1. Open Dungeon screen
2. Click Info → verify estimated range = computed range
3. Click a dungeon, resolve battle
4. Check: rewards are within estimated range
5. Check: State.gold updated correctly
6. Check: Telemetry events logged
```

---

**Version:** 1.2 (Improved mechanics, fixed parser errors)
**Last Updated:** 2026-01-04
