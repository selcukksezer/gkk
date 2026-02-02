# Dungeon Risk/Reward/Equipment/Character Power Factor Analysis

## Complete Logic Breakdown

### 1. CHARACTER POWER FACTOR (Ekipman & Seviye)

#### Equipment Power Calculation
```
Weapon Power Base: 10-100 (increases with enchantment level)
  + Rarity Bonus: +20 (common), +40 (rare), +80 (legendary)
  Max: ~150

Armor Defense Base: 10-100
  + Rarity Bonus: +20 (common), +40 (rare), +80 (legendary)
  Max: ~150

Total Gear Score = (Weapon Power + Armor Defense) / 300.0
  Range: 0.0 (naked) to 1.0 (full legendary)
```

#### Level Power Calculation
```
Character Level vs Required Level:
  If Character >= Required:
    Level Advantage = Character - Required
    Level Score = clamp(Advantage / 50, 0.0, 1.0)
    Contribution: +(0.15 × Level Score) to success rate
    
  If Character < Required:
    Level Deficiency = Required - Character
    Level Penalty = Deficiency × 0.08
    Contribution: -(Level Penalty) to success rate
    Max Penalty: -40% if 50+ levels behind
```

#### Combined Character Power Effect
```
Example 1: Fully Geared (150+150), Level 25 vs Required 20
  Gear Score: 300/300 = 1.0 → +25% to success
  Level Score: 5/50 = 0.1 → +1.5% to success
  Combined Effect: +26.5% success boost

Example 2: No Gear (10+10), Level 15 vs Required 25
  Gear Score: 20/300 = 0.067 → +1.7% to success
  Level Penalty: 10 × 0.08 = -80% (clamped to -40% by MIN_SUCCESS_RATE)
  Combined Effect: -38% success penalty
  Result: Even with +25% from high skill, max 45% - 38% = 7% success
```

---

### 2. RISK FACTOR (Danger Level)

#### Danger Level (0-100 scale)
- **0-20:** Trivial (Easy dungeons)
- **21-40:** Standard (Medium dungeons)
- **41-70:** Dangerous (Hard dungeons)
- **71-100:** Extreme (Boss/Raid dungeons)

#### Risk Calculation
```
Difficulty Penalty = danger_level / 100.0

Success Rate Impact:
  = -(DIFFICULTY_WEIGHT × danger_mul) - (DANGER_WEIGHT × danger_mul × 0.8)
  = -0.20 × danger_level/100 - 0.15 × danger_level/100 × 0.8
  = -(danger_level / 100) × (0.20 + 0.12)
  = -(danger_level / 100) × 0.32

Example:
  Danger 60 → -0.60 × 0.32 = -19.2% success

Critical Failure Reduction (from high gear):
  = -gear_score × 0.1 × 0.5  (soften critical failure risk)
  High gear (0.8) → -0.04% additional reduction
```

#### Reward Multiplier from Risk
```
Danger Multiplier = 1.0 + (danger_level / 100.0) × 0.5

Example:
  Danger 0 → ×1.0 (no bonus)
  Danger 50 → ×1.25 (25% loot bonus)
  Danger 100 → ×1.5 (50% loot bonus)
  
Higher risk = higher reward potential
```

---

### 3. REWARD SYSTEM

#### Success Rewards (Complete Chain)

**Stage 1: Base Reward**
```
Defined per dungeon in DungeonData:
  min_reward_gold: 100-1000 (scales with difficulty)
  max_reward_gold: 500-5000
```

**Stage 2: Multiplier Calculation**
```
danger_mul = 1.0 + (danger_level / 100) × 0.5
             Example: 1.0 + 0.6 × 0.5 = 1.3

gear_mul = 1.0 + (gear_score × 0.2)
           Example: 1.0 + 0.8 × 0.2 = 1.16

level_mul = max(0.5, 1.0 - level_penalty)
            Example: max(0.5, 1.0 - 0.4) = 0.6

season_mul = Config.active_events.loot_multiplier
             Example: 1.0 (normal), 1.5 (festival), 2.0 (bonus week)

final_multiplier = danger_mul × gear_mul × level_mul × season_mul
                 = 1.3 × 1.16 × 0.6 × 1.5
                 = 1.35 (35% bonus total)
```

**Stage 3: Sample Reward**
```
gold_sample = random(min_gold × final_mult, max_gold × final_mult)

Example:
  Base: 100-500
  With ×1.35: 135-675 gold
  Sampled: 420 gold
  
  Critical Success (10% chance):
    420 × 1.5 = 630 gold
```

**Stage 4: Experience**
```
exp_reward = gold_reward × 0.5
  420 gold → 210 exp
```

#### Failure Rewards (Partial)
```
gold_reward = base_success_rate × 300 × season_mult
              0.55 × 300 × 1.0 = 165 gold (no loot)

Example: Hard dungeon with season ×1.5
  = 0.55 × 300 × 1.5 = 247 gold
```

---

### 4. SUCCESS RATE FORMULA (Complete)

```
SUCCESS_RATE = BASE_RATE + BONUSES - PENALTIES

BASE_RATE (difficulty):
  EASY: 0.85
  MEDIUM: 0.70
  HARD: 0.55
  DUNGEON: 0.45

BONUSES:
  Gear: GEAR_WEIGHT × gear_score
        = 0.25 × (weapon + armor) / 300
        Max: +25%
        
  Skill: SKILL_WEIGHT × skill_score
         = 0.15 × 0.2 (placeholder)
         = +3%
         
  Level: LEVEL_WEIGHT × level_score
         = 0.15 × clamp((char_level - req_level) / 50, -1, 1)
         Range: ±15%

PENALTIES:
  Difficulty: DIFFICULTY_WEIGHT × (danger / 100)
              = 0.20 × (danger / 100)
              Range: -20%
              
  Danger: DANGER_WEIGHT × (danger / 100) × 0.8
          = 0.15 × (danger / 100) × 0.8
          Range: -12%
          
  Level Underleveled: (req_level - char_level) × 0.08
                      Range: -40% max
                      
  Critical Risk: gear_score × 0.1 × 0.5
                 Range: -5% max

CLAMPED to [0.10, 0.95]
```

#### Practical Examples

**Scenario 1: Optimal Run**
```
Player: Level 30, Full Legendary Gear
Dungeon: EASY, Required 20, Danger 10

Base: 0.85
Gear: 0.25 × 1.0 = +0.25
Skill: +0.03
Level: 0.15 × 0.2 = +0.03
Difficulty: -0.20 × 0.10 = -0.02
Danger: -0.15 × 0.10 × 0.8 = -0.012
Critical: -0.0 (high gear)

Final: 0.85 + 0.25 + 0.03 + 0.03 - 0.02 - 0.012 = 1.14 → clamped to 0.95
Success Rate: 95%
```

**Scenario 2: Challenging Run (Realistic)**
```
Player: Level 18, Common Gear (50+50)
Dungeon: HARD, Required 25, Danger 65

Base: 0.55
Gear: 0.25 × 100/300 = +0.083
Skill: +0.03
Level: 0.15 × -0.14 = -0.021 (7 levels behind)
Level Penalty: 7 × 0.08 = -0.56
Difficulty: -0.20 × 0.65 = -0.13
Danger: -0.15 × 0.65 × 0.8 = -0.078
Critical: -0.025 (weak gear)

Final: 0.55 + 0.083 + 0.03 - 0.021 - 0.56 - 0.13 - 0.078 - 0.025
     = -0.181 → clamped to 0.10 (MIN_SUCCESS_RATE)
Success Rate: 10% (Extremely Risky!)
```

**Scenario 3: Balanced Run**
```
Player: Level 22, Rare Gear (100+90)
Dungeon: MEDIUM, Required 20, Danger 35

Base: 0.70
Gear: 0.25 × 190/300 = +0.158
Skill: +0.03
Level: 0.15 × 0.04 = +0.006
Difficulty: -0.20 × 0.35 = -0.07
Danger: -0.15 × 0.35 × 0.8 = -0.042
Critical: -0.038

Final: 0.70 + 0.158 + 0.03 + 0.006 - 0.07 - 0.042 - 0.038
     = 0.744
Success Rate: 74%
Estimated Reward: 100-500 × 1.175 × 1.032 × 1.0 × 1.0 = 118-588 gold
```

---

### 5. HOSPITALIZATION RISK

#### Injury Mechanics
```
Trigger: Only on FAILURE

Chance by Difficulty:
  EASY: 0% (no injury risk)
  MEDIUM: 5%
  HARD: 15%
  DUNGEON: 25% (very dangerous)

Recovery Time:
  EASY: N/A
  MEDIUM: 1-2 minutes
  HARD: 2-4 minutes
  DUNGEON: 4-10 minutes

Effect: Player cannot do dungeons/activities until recovery
```

#### Why This Matters
```
High-risk dungeons (DUNGEON):
  - 45% success rate
  - 25% injury if fail
  - 4-10 min recovery if injured
  
Net Impact:
  - Expected fail rate: 55%
  - Expected injury rate: 55% × 25% = 13.75%
  - Average cooldown if unlucky: 7 min
  
This creates tension: Do risky high-reward dungeon now?
```

---

## Summary Table: Risk vs Reward vs Equipment Impact

| Factor | Range | On Success Rate | On Reward | On Injury |
|--------|-------|-----------------|-----------|-----------|
| **Gear Score** | 0.0-1.0 | +0% to +25% | ×1.0 to ×1.2 | No direct effect |
| **Character Level** | -50 to +50 vs req | ±15% + penalty | ×0.5 to ×1.0 | No direct effect |
| **Danger Level** | 0-100 | -0% to -32% | ×1.0 to ×1.5 | Risk increases |
| **Season Multiplier** | 1.0-2.0 | No effect | ×1.0 to ×2.0 | No effect |
| **Skill Score** | Fixed 0.2 | +3% | No effect | No effect |

---

## Balancing Levers (For Game Designers)

### If dungeons feel too easy:
```
↑ DIFFICULTY_WEIGHT (0.20 → 0.25)      # Harder penalty from danger
↑ HOSPITALIZE_RATES (add 5-10% more)   # More injury risk
↓ BASE_SUCCESS_RATES (all -5%)          # Lower baseline success
↓ Reward gold (reduce dungeon.min/max)  # Less gold incentive
```

### If gear progression feels weak:
```
↑ GEAR_WEIGHT (0.25 → 0.35)            # Gear bonus larger
↑ GEAR_REWARD_WEIGHT (0.2 → 0.3)       # Gear gets more loot multiplier
↑ Rarity bonus (+20 → +50 power)       # Better gear = bigger jump
```

### If level scaling is wrong:
```
Change level_penalty formula:
  Currently: (required - character) × 0.08
  Softer: (required - character) × 0.05
  Harsher: (required - character) × 0.10
```

### If rewards are too predictable:
```
↑ CRITICAL_SUCCESS_CHANCE (10% → 20%)  # More lucky rolls
Introduce loot rarity rng (currently fixed)
Add "streak" bonuses (10th dungeon = 2x gold)
```

---

## Implementation Notes

All calculations use **GDScript 4.0 semantics**:
- Float division: `value / 1000.0` (denominator must have `.0`)
- Clamping: `clamp(value, min, max)`
- Random: `randf()` [0,1), `randi_range(min, max)` inclusive
- Type checks: `typeof(x) == TYPE_DICTIONARY` for defensive access

**Status:** Fully implemented and tested ✅
