# Magical Research Minigame - Godot Implementation

A complete implementation of a strategic spell research minigame with resource management, board manipulation, and dynamic weather effects.

## Overview

This system implements a turn-based research minigame where players construct magical theories by placing and integrating tiles on a 3×3 grid. Success requires balancing stability (Cohesion) against power, managing limited resources (Focus and Insight), and adapting to changing epistemic conditions (Weather).

## Core Components

### 1. ResearchTile.gd
Represents individual theory tiles with:
- **Tags**: CONSENSUS, TENUOUS, or CRACKPOT
- **Integration Levels**: Progressive strengthening (0 to max)
- **Volatility**: Stability cost that decreases with integration
- **Effects**: Power that scales with integration level

**Maximum Integration by Tag:**
- Consensus: 3 levels
- Tenuous: 2 levels
- Crackpot: 1 level

### 2. ResearchBoard.gd
Manages the 3×3 grid and tile relationships:
- Orthogonal adjacency detection
- Adjacency pressure calculation
- Board state queries (tile counts, links, etc.)
- Persistence support

**Adjacency Pressure Rules:**
| Tile Pair | Base Pressure | Integrated (50%) |
|-----------|--------------|------------------|
| Consensus-Consensus | +1 | +1 |
| Consensus-Tenuous | 0 | 0 |
| Tenuous-Tenuous | 0 | 0 |
| Consensus-Crackpot | -1 | -1 (min) |
| Tenuous-Crackpot | -1 | -1 (min) |
| Crackpot-Crackpot | -2 | -1 |

### 3. ResearchWeather.gd
Epistemic conditions that change every 3 turns:
- **INSPIRED**: +1 Insight per turn
- **DOGMATIC**: -1 Insight cost for integration
- **CHAOTIC**: Double crackpot adjacency penalties
- **STAGNANT**: Draw only 1 tile instead of 2
- **VOLATILE**: -1 Cohesion per turn
- **HARMONIOUS**: +1 Cohesion if consensus tiles present
- **RIGID**: +1 Insight cost for crackpot integration
- **CLEAR**: No modifiers

### 4. SpellIntent.gd
Defines research goals and requirements:
- Domain (Light, Shadow, Fire, Ice, Force, Mind, Life, Death)
- Constraints (e.g., "low_intensity", "non_combat")
- Desired effects
- Completion requirements (min cohesion, tiles, links)
- Available tile pool generation

### 5. ResearchSession.gd
Main gameplay controller managing:
- Resource tracking (Focus, Insight, Cohesion)
- Turn progression
- Action execution
- Weather cycling
- Win/loss conditions
- Session persistence

## Resources

### Focus (Hard Limit)
- Starting: 10 per session
- Cost: -1 per turn
- Used for: All actions
- Session ends when depleted

### Insight (Soft Cap at 6)
- Starting: 2 per session
- Gained from: Integration, weather effects
- Used for: Integration, stabilization, powerful actions

### Cohesion (Theory Health)
- Starting: 10 per session
- Affected by: Volatility, adjacency pressure, weather
- Session fails if reaches 0
- Required minimum to complete spell (typically 6+)

## Actions

### Examine Source (1 Focus)
Draw 2 random tiles from pool (1 if Stagnant weather)

### Place Tile (1 Focus)
Place tile at integration level 0
Apply volatility penalty to Cohesion

### Integrate Tile (1 Focus + Variable Insight)
Increase tile integration by 1 level
**Insight costs:**
- Consensus: 1 × level
- Tenuous: 2 × level
- Crackpot: 3 × level

**Cohesion changes:**
- Consensus: +1
- Tenuous: 0
- Crackpot: -1

**Limits:**
- Max 3 integration levels gained per session

### Stabilize Theory (1 Focus + 1 Insight)
Cohesion +3

### Speculative Leap (2 Focus + 2 Insight)
Generate powerful Crackpot tile
Cohesion -2

### Complete Spell (Free)
Attempt to finish research
Checks all requirements

## Turn Structure

1. Weather effects apply
2. Adjacency pressure calculated and applied
3. Player performs one action
4. Focus -1
5. Weather timer advances (changes every 3 turns)
6. Check for session end conditions

## Completion Requirements

Configurable per spell intent, typically:
- Minimum Cohesion: 6+
- Minimum Integrated Tiles: 4+
- Minimum Adjacency Links: 5+

## Usage Example

```gdscript
# Create spell intent
var intent = SpellIntent.new(
	SpellIntent.SpellDomain.LIGHT,
	["low_intensity"],
	["illumination"]
)

# Start session
var session = ResearchSession.new(intent)
session.start_session()

# Perform actions
var tiles = session.action_examine_source()
session.action_place_tile(tiles.tiles_drawn[0], Vector2i(1, 1))
session.advance_turn()

session.action_integrate_tile(Vector2i(1, 1))
session.advance_turn()

# Check completion
var result = session.action_complete_spell()
if result.success:
	print("Spell completed!")
```

## Signals

### ResearchSession Signals
- `session_started()` - Session begins
- `session_ended(reason: String, success: bool)` - Session ends
- `turn_advanced(turn_number: int)` - Turn completes
- `weather_changed(new_weather: ResearchWeather)` - Weather updates
- `resource_changed(resource_name: String, new_value: int)` - Resource updates
- `cohesion_changed(new_value: int)` - Cohesion updates
- `action_performed(action_name: String, result: Dictionary)` - Action completes

## Save/Load Integration

All classes support serialization via `to_dict()` and `from_dict()` methods, integrating with the existing SaveSystem and LoadSystem:

```gdscript
# Save
var session_data = [session]
SaveSystem.save_game(session_data, "save_slot_1", "research.dat")

# Load
var loaded = LoadSystem.load_game("save_slot_1", "research.dat")
var session = loaded[0] as ResearchSession
```

## Design Principles

1. **No Perfect Safety**: Every action carries risk
2. **Power-Risk Tradeoff**: Crackpot tiles are strong but destabilizing
3. **Asymptotic Stability**: Perfect safety is impossible
4. **Meaningful Revisiting**: Sessions can be resumed and refined
5. **Weather Forces Adaptation**: Cannot simply wait out bad conditions
6. **Integration Limits**: Prevents single-session perfection

## Strategic Depth

- **Early Game**: Focus on drawing and placing stable tiles
- **Mid Game**: Balance integration with cohesion management
- **Late Game**: Fine-tune adjacencies and meet requirements
- **Weather**: Adapt strategy to current conditions
- **Crackpot Usage**: High risk, high reward when positioned carefully
- **Session Planning**: Multiple sessions expected for complex spells

## File Dependencies

Required files for full system:
1. ResearchTile.gd
2. ResearchBoard.gd
3. ResearchWeather.gd
4. SpellIntent.gd
5. ResearchSession.gd
6. SaveSystem.gd (from existing save system)
7. LoadSystem.gd (from existing save system)
8. SaveLoadConfig.gd (from existing save system)

Optional:
- ResearchDemo.gd (demonstration script)

## Extension Points

### Custom Tile Types
Extend `ResearchTile` to add:
- Special abilities
- Triggered effects
- Conditional bonuses

### Custom Weather
Add new weather types in `ResearchWeather.WeatherType`

### Custom Domains
Add domains to `SpellIntent.SpellDomain` with unique tile pools

### UI Integration
Connect signals to update visual displays:
- Board visualization
- Resource meters
- Weather indicators
- Tile hand display

## Performance Notes

- Board calculations are O(n) where n = placed tiles (max 9)
- Adjacency checks are optimized with position-based lookups
- Weather effects are event-driven, not polled
- Save/load uses existing optimized serialization system

## Testing

Run `ResearchDemo.gd` to see:
- Complete session flow
- Action execution
- Weather effects
- Save/load functionality
- Board state analysis
- Adjacency mechanics

## License

This implementation follows the design document "Research Minigame Design.txt" and integrates with the existing Godot save/load system.
