# Research Minigame - Quick Reference Guide

## Resources at a Glance

| Resource | Starting | Limit | Usage |
|----------|----------|-------|-------|
| Focus | 10 | Hard (session ends at 0) | All actions cost 1-2 |
| Insight | 2 | Soft cap at 6 | Integration, special actions |
| Cohesion | 10 | Failure at 0 | Theory health |

## Tile Tags

| Tag | Max Integration | Volatility | Adjacency Bonus | Notes |
|-----|----------------|------------|----------------|-------|
| Consensus | 3 | 1 | +10% | Stable, weak |
| Tenuous | 2 | 2 | 0% | Balanced |
| Crackpot | 1 | 3 | +20% | Powerful, volatile |

## Action Reference

| Action | Focus | Insight | Effect |
|--------|-------|---------|--------|
| Examine Source | 1 | 0 | Draw 2 tiles (1 if Stagnant) |
| Place Tile | 1 | 0 | Add tile at level 0, apply volatility |
| Integrate | 1 | 1-9 | Increase level by 1 |
| Stabilize | 1 | 1 | +3 Cohesion |
| Speculative Leap | 2 | 2 | Generate Crackpot tile, -2 Cohesion |

## Integration Costs (Insight)

| Tag | Level 1 | Level 2 | Level 3 |
|-----|---------|---------|---------|
| Consensus | 1 | 2 | 3 |
| Tenuous | 2 | 4 | - |
| Crackpot | 3 | - | - |

**Modified by Dogmatic weather: -1 cost**
**Modified by Rigid weather: +1 cost for Crackpot only**

## Integration Cohesion Changes

| Tag | Per Level |
|-----|-----------|
| Consensus | +1 |
| Tenuous | 0 |
| Crackpot | -1 |

## Adjacency Pressure (Per Turn)

| Tile Pair | Unintegrated | Both Integrated |
|-----------|--------------|----------------|
| Consensus × Consensus | +1 | +1 |
| Consensus × Tenuous | 0 | 0 |
| Tenuous × Tenuous | 0 | 0 |
| Consensus × Crackpot | -1 | -1 |
| Tenuous × Crackpot | -1 | -1 |
| Crackpot × Crackpot | -2 | -1 |

**Chaotic weather doubles crackpot penalties**

## Weather Effects

| Weather | Effect |
|---------|--------|
| Inspired | +1 Insight per turn |
| Dogmatic | Integration costs -1 Insight |
| Chaotic | Crackpot penalties ×2 |
| Stagnant | Examine draws only 1 tile |
| Volatile | -1 Cohesion per turn |
| Harmonious | +1 Cohesion if consensus present |
| Rigid | Crackpot integration +1 Insight |
| Clear | No effects |

**Weather changes every 3 turns**

## Typical Completion Requirements

| Requirement | Typical Value | Notes |
|-------------|---------------|-------|
| Min Cohesion | 6+ | Must survive to completion |
| Min Integrated Tiles | 4+ | Can't just place everything |
| Min Adjacency Links | 5+ | Encourages compact layouts |

## Session Limits

- **Max integrations per session**: 3 levels total
- **Focus per turn**: -1 automatic
- **Weather duration**: 3 turns fixed

## Strategic Tips

1. **Start Safe**: Place Consensus tiles early
2. **Weather Timing**: Integrate during Dogmatic weather
3. **Crackpot Placement**: Isolate or pair with integrated tiles
4. **Stabilize Early**: Use when Cohesion drops below 7
5. **Integration Planning**: Save Insight for critical integrations
6. **Multiple Sessions**: Complex spells need 2-3 sessions

## Winning Strategy Pattern

1. **Session 1**: Place 4-5 stable tiles, integrate 2-3
2. **Session 2**: Add power tiles, integrate remaining
3. **Session 3**: Fine-tune and complete

## Common Mistakes

- Placing too many tiles without integration
- Ignoring weather effects
- Using Speculative Leap too early
- Running out of Insight before critical integrations
- Placing Crackpot tiles adjacent to each other

## Emergency Recovery

| Situation | Solution |
|-----------|----------|
| Low Cohesion (3-5) | Stabilize Theory immediately |
| Low Insight | Wait for Inspired weather |
| Bad tile draw | Use what you have, revisit later |
| Chaotic + Crackpots | Remove or integrate crackpots |
| Running out of Focus | Plan to complete or abandon |

## Code Quick Start

```gdscript
# Minimal working example
var intent = SpellIntent.new(SpellIntent.SpellDomain.LIGHT)
var session = ResearchSession.new(intent)
session.start_session()

# Main loop
while session.state == ResearchSession.SessionState.IN_PROGRESS:
    # Your action here
    session.advance_turn()
```

## File Structure

```
project/
├── ResearchTile.gd          # Tile data structure
├── ResearchBoard.gd         # 3×3 grid manager
├── ResearchWeather.gd       # Epistemic conditions
├── SpellIntent.gd          # Research goals
├── ResearchSession.gd      # Main game controller
├── ResearchSystemRegistry.gd # Save/load registration
├── ResearchDemo.gd         # Usage examples
└── README_RESEARCH.md      # Full documentation
```

## Signal Connections

```gdscript
session.session_started.connect(_on_session_start)
session.session_ended.connect(_on_session_end)
session.turn_advanced.connect(_on_turn_advance)
session.weather_changed.connect(_on_weather_change)
session.resource_changed.connect(_on_resource_change)
session.cohesion_changed.connect(_on_cohesion_change)
session.action_performed.connect(_on_action_done)
```

## Persistence

```gdscript
# Save
SaveSystem.save_game([session], "slot1", "research.dat")

# Load
var loaded = LoadSystem.load_game("slot1", "research.dat")
var session = loaded[0] as ResearchSession
```
