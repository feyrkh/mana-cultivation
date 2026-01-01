# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mana Cultivation is a Godot 4.5 game featuring a magical research minigame. The core gameplay involves placing spell tiles on a 3x3 grid with integration mechanics, adjacency effects, and resource management (Focus, Insight, Cohesion).

## Running the Project

- Open in Godot 4.5 (GL Compatibility renderer)
- Press F5 or Play to run the main scene
- Demo scenes can be run individually by right-clicking in the FileSystem panel

**Demo scenes for testing subsystems:**
- `demo/ResearchDemo.tscn` - Research minigame
- `util/saveSystem/demo/GenericSerializerDemo.tscn` - Serialization system
- `util/toolbar/ToolbarDemo.tscn` - Toolbar/tooltip system
- `util/ui/camera/DraggableCamera2DDemo.tscn` - Camera controls

## Architecture

### Autoloads (initialized at startup)
- `SaveLoadConfig` - Save system configuration
- `ResourceMgrRegistry` - Centralized resource managers for SpellFormTile and SpellDomain

### Core Systems

**Save/Load System (`util/saveSystem/`)**
- `GenericSerializer` - Reflection-based serialization supporting all Godot types, nested objects, and typed arrays/dictionaries
- `RegisteredObject` - Base class for objects with unique IDs that serialize as references
- `InstanceRegistry` - Singleton managing canonical instances by type and ID
- `ResourceMgr` - Loads game data from JSON files with caching

**Data-Driven UI (`util/modelRenderSystem/`)**
- `FormFieldSchema` - Declarative UI field definitions using builder pattern (`with_min()`, `with_max()`, etc.)
- `AutoFormBuilder` - Generates forms from model objects with edit/view modes
- Objects define `get_schema() -> Array[FormFieldSchema]` to specify their UI

**Research Minigame (`game/research/`)**
- `SpellForm` - 3x3 grid with slot states (EMPTY/OCCUPIED/BLOCKED)
- `SpellFormTile` - Tiles with categories (consensus/tenuous/crackpot), integration levels, adjacency effects, synergies
- `SpellDomain` - Spell domain types (Light, Dark, Poison, etc.)
- `AdjacencyEffect` / `SynergyEffect` - Tile interaction mechanics

### Data Layer

Game data is stored as JSON in `data/`:
- `data/SpellDomain/` - Domain definitions
- `data/SpellformTile/` - Tile definitions

JSON format uses GenericSerializer with `__class__` and `__id__` markers. RegisteredObjects are stored as references.

### UI Components

**Toolbar (`util/toolbar/`)** - Action/selection items with nested tooltip navigation, TAB-lock support

**DraggableCamera2D (`util/ui/camera/`)** - Control-based camera with zoom, pan, bounded viewports

## Key Patterns

**Serialization**: All persistent data uses `GenericSerializer`. RegisteredObjects serialize by reference (ID), not value. Custom types implement `to_dict()`/`from_dict()`.

**Property typing**: Use `Array[Type]` and `Dictionary[K,V]` syntax. TypedPropertyAssigner handles type coercion.

**Signals**: Use descriptive names (`edit_confirmed`, `action_triggered`). Connect for state changes and user actions.

## Game Design Reference

See `design/Research Minigame Design.txt` for complete rules:
- Sessions have Focus (time), Insight (power), Cohesion (health)
- Integration levels scale effects and reduce volatility
- Adjacency pressure affects cohesion based on tile category pairings
- Weather conditions change every 3 turns
