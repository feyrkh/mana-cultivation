# DraggableCamera2D Control System

A flexible Control-based camera system for Godot 4 that supports zooming, panning, and bounded viewports.

## Features

- ✅ **Independent Cameras**: Multiple cameras can exist in the same scene, each with its own state
- ✅ **Smooth Zooming**: Mouse wheel zoom with progressive increment scaling near extremes
- ✅ **Cursor-Stable Zoom**: The point under the cursor stays fixed during zoom
- ✅ **Middle-Mouse Panning**: Drag to pan with accurate cursor tracking
- ✅ **Bounded Viewport**: Soft-locked to a configurable rectangular region
- ✅ **Elastic Bounds**: Smooth return to bounds when viewport exceeds limits
- ✅ **Center-Based Positioning**: Setting position sets the viewport center, not top-left

## Usage

### Basic Setup

```gdscript
# Create a camera
var camera = DraggableCamera2D.new()
camera.custom_minimum_size = Vector2(400, 400)
add_child(camera)

# Add content to the camera
var content_node = Panel.new()
content_node.position = Vector2(100, 100)
content_node.size = Vector2(50, 50)
camera.add_content(content_node)
```

### Configuration

```gdscript
# Zoom settings
camera.min_zoom = 0.25
camera.max_zoom = 4.0
camera.zoom_speed = 0.1  # Base zoom increment
camera.zoom_smoothing = 0.3  # Reduction factor near extremes

# Pan settings
camera.pan_button = MOUSE_BUTTON_MIDDLE
camera.enable_pan = true

# Bounds settings
camera.enable_bounds = true
camera.set_bounds(Rect2(-500, -500, 1000, 1000))
camera.bounds_elasticity = 5.0  # Return speed
camera.bounds_margin = 50.0  # Grace margin before forcing return
```

### Public API

```gdscript
# Set zoom level
camera.set_zoom(2.0)  # Zoom to 2x at viewport center
camera.set_zoom(2.0, Vector2(100, 100))  # Zoom keeping point stable

# Set camera position (centers viewport at this point)
camera.set_position(Vector2(0, 0))

# Get current state
var zoom = camera.get_zoom()
var pos = camera.get_position()

# Add/remove content
camera.add_content(my_node)
camera.remove_content(my_node)

# Get content container
var container = camera.get_content_container()

# Update bounds
camera.set_bounds(Rect2(-1000, -1000, 2000, 2000))

# Get viewport in world coordinates
var viewport = camera.get_viewport_rect_world()
```

### Signals

```gdscript
# Connect to camera events
camera.zoom_changed.connect(_on_zoom_changed)
camera.position_changed.connect(_on_position_changed)

func _on_zoom_changed(new_zoom: float):
	print("Zoom: ", new_zoom)

func _on_position_changed(new_pos: Vector2):
	print("Position: ", new_pos)
```

## How It Works

### Zoom Smoothing

As zoom approaches min/max limits, the increment size decreases quadratically:
- At extremes: 10% of base speed
- At center: 100% of base speed

This creates a natural "resistance" feeling near zoom limits.

### Pan Mechanics

1. When you click and drag, the system:
   - Records the initial screen position and camera position
   - Calculates screen-space delta during drag
   - Converts delta to world-space (accounting for zoom)
   - Updates camera position inversely (so dragging right moves view left)

2. The math ensures the point under your cursor stays under your cursor regardless of zoom level.

### Bounds System

The camera enforces bounds with two stages:

1. **Grace Margin**: Viewport can exceed bounds by `bounds_margin` pixels
2. **Elastic Return**: Once exceeded, camera smoothly returns at `bounds_elasticity` speed

This creates a "soft lock" that feels natural rather than rigid.

### Coordinate Systems

- **Screen Space**: Pixel coordinates in the camera Control (0,0 = top-left corner)
- **World Space**: Logical coordinates in your content (0,0 = configurable center)
- **Camera Position**: Always refers to the *center* of the viewport in world space

## Example Use Cases

### Research Board (from your project)

```gdscript
var research_camera = DraggableCamera2D.new()
research_camera.set_bounds(Rect2(-400, -400, 800, 800))
research_camera.min_zoom = 0.5
research_camera.max_zoom = 3.0

# Add 3x3 tile grid
for row in range(3):
	for col in range(3):
		var tile = create_research_tile()
		tile.position = Vector2(col * 100, row * 100)
		research_camera.add_content(tile)
```

### Multiple Independent Cameras

```gdscript
# Spell composition view
var spell_camera = DraggableCamera2D.new()
spell_camera.set_bounds(Rect2(-500, -500, 1000, 1000))

# Inventory view
var inventory_camera = DraggableCamera2D.new()
inventory_camera.set_bounds(Rect2(0, 0, 800, 600))

# Both cameras can zoom/pan independently in the same UI
```

## Performance Notes

- Content is transformed via a single container node (efficient)
- Bounds checking only occurs when camera moves
- No unnecessary updates when state doesn't change
- Suitable for hundreds of content nodes

## Demo

Run `DraggableCamera2DDemo.tscn` to see:
- Two independent cameras side-by-side
- Grid pattern vs circular pattern content
- Different zoom ranges and bounds
- Real-time zoom/position display

## Integration with Your Project

Perfect for:
- Research board viewing (magical research minigame)
- Character/inventory panels
- Spell composition interface
- Any zoomable/pannable content area

The camera works with your existing systems:
- Compatible with `ModelRenderer` for data display
- Works inside `DragDropContainer` layouts
- Can display `Character` and `StatusEffect` data
- Integrates with save/load system (save camera state as data)
