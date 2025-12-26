# Toolbar System Documentation

A flexible, feature-rich toolbar system for Godot 4 with action items, selection items, and intelligent tooltip management with nested navigation.

## Features

### 1. Action Items
- Trigger immediate callbacks when clicked
- Ideal for commands like Save, Undo, Redo, etc.
- No visual selection state

### 2. Selection Items
- Can be marked as "selected" within the toolbar
- Visual indication of selected state
- Supports single or multiple selection modes
- Query current selection at any time

### 3. Intelligent Tooltips
- Hover-to-show with configurable delay (default 300ms)
- Automatic positioning to stay on screen
- Smart anchor positioning that avoids overlapping the source item
- Preferred direction with automatic fallback
- Lock tooltips with TAB key (or ui_lock action)
- Nested tooltip navigation via clickable links
- Stack management for multiple locked tooltips

## Components

### ToolbarItem (Base Class)
Base class for all toolbar items with common functionality:
- Icon and text display
- Hover detection
- Selection state management
- Tooltip triggering

### ActionItem
Extends ToolbarItem for immediate action execution:
```gdscript
signal action_triggered(item_id: String)
```

### SelectionItem
Extends ToolbarItem for selectable tools:
```gdscript
signal selection_changed(item_id: String, selected: bool)
```

### Toolbar
Main container that orchestrates everything:
```gdscript
# Properties
@export var tooltip_direction: TooltipDirection = TooltipDirection.UP
@export var allow_multiple_selection: bool = false

# Signals
signal action_triggered(item_id: String)
signal selection_changed(item_id: String)

# Key Methods
func add_action_item(item_id: String, text: String, icon: Texture2D = null, tooltip_id: String = "") -> ActionItem
func add_selection_item(item_id: String, text: String, icon: Texture2D = null, tooltip_id: String = "") -> SelectionItem
func register_tooltip(tooltip_id: String, title: String, body: String, links: Array[Dictionary] = []) -> void
func get_selected_item() -> SelectionItem
func get_selected_items() -> Array[SelectionItem]
func get_selected_item_id() -> String
```

### TooltipWindow
Floating panel that displays tooltip content:
- Automatic positioning relative to anchor item
- Lock/unlock functionality
- Close button when locked
- Click outside to close when locked

### TooltipContent
Displays formatted tooltip information:
- Title section
- Body text with word wrapping
- Clickable links to nested tooltips

### TooltipRegistry
Central registry for all tooltip definitions:
```gdscript
func register_tooltip(tooltip_id: String, title: String, body: String, links: Array[Dictionary] = []) -> void
func get_tooltip_data(tooltip_id: String) -> Dictionary
func has_tooltip(tooltip_id: String) -> bool
```

## Usage Examples

### Basic Setup

```gdscript
extends Control

@onready var toolbar: Toolbar

func _ready() -> void:
	toolbar = Toolbar.new()
	add_child(toolbar)
	
	# Register tooltips
	toolbar.register_tooltip(
		"tool_pencil",
		"Pencil Tool",
		"Draw freehand lines and shapes.",
		[
			{"text": "Brush Settings", "tooltip_id": "settings_brush"}
		]
	)
	
	# Add items
	toolbar.add_selection_item("tool_pencil", "Pencil", null, "tool_pencil")
	toolbar.add_action_item("action_save", "Save", null, "action_save")
	
	# Connect signals
	toolbar.action_triggered.connect(_on_action_triggered)
	toolbar.selection_changed.connect(_on_selection_changed)

func _on_action_triggered(item_id: String) -> void:
	print("Action: " + item_id)

func _on_selection_changed(item_id: String) -> void:
	print("Selection: " + item_id)
```

### Nested Tooltips

Create a network of related tooltips:

```gdscript
# Parent tooltip
toolbar.register_tooltip(
	"main_topic",
	"Main Topic",
	"This is the main explanation.",
	[
		{"text": "Subtopic A", "tooltip_id": "subtopic_a"},
		{"text": "Subtopic B", "tooltip_id": "subtopic_b"}
	]
)

# Child tooltips
toolbar.register_tooltip(
	"subtopic_a",
	"Subtopic A",
	"Details about subtopic A.",
	[
		{"text": "Back to Main", "tooltip_id": "main_topic"},
		{"text": "Related: Subtopic B", "tooltip_id": "subtopic_b"}
	]
)
```

### Multiple Selection Mode

```gdscript
toolbar.allow_multiple_selection = true

# Later, get all selected items
var selected = toolbar.get_selected_items()
for item in selected:
	print("Selected: " + item.item_id)
```

### Custom Tooltip Direction

Position tooltips in different directions based on toolbar location:

```gdscript
# For bottom toolbar, show tooltips above
toolbar.tooltip_direction = Toolbar.TooltipDirection.UP

# For top toolbar, show tooltips below
toolbar.tooltip_direction = Toolbar.TooltipDirection.DOWN

# For side toolbars
toolbar.tooltip_direction = Toolbar.TooltipDirection.LEFT  # or RIGHT
```

## Tooltip Positioning Logic

The system uses intelligent positioning:

1. **Preferred Direction**: Start with the configured direction (UP/DOWN/LEFT/RIGHT)
2. **Screen Constraints**: Keep tooltip within viewport bounds
3. **Overlap Prevention**: If tooltip would overlap the anchor item, try opposite direction
4. **Final Adjustment**: Clamp position to ensure complete visibility

This ensures tooltips are always readable and never overlap their trigger item.

## Locking Tooltips

Users can press **TAB** (or the `ui_lock` action) to lock the current tooltip:

1. Locked tooltips won't disappear when mouse moves away
2. A close button (×) appears in the top corner
3. Click outside to close a locked tooltip
4. Multiple tooltips can be locked, creating a stack
5. New tooltips can be opened from links in locked tooltips

This enables easy navigation through complex tooltip networks without losing context.

## Input Mapping

The system uses the `ui_lock` action for locking tooltips. To set this up:

1. Go to Project → Project Settings → Input Map
2. Add a new action called `ui_lock`
3. Assign it to TAB key or your preferred key

Alternatively, the system automatically handles TAB key presses even without the action defined.

## Best Practices

### 1. Tooltip Organization
- Keep tooltip text concise (2-3 sentences)
- Use links for detailed explanations
- Create logical navigation paths between related tooltips

### 2. Link Structure
- Provide "back" links to parent topics
- Link to related topics
- Avoid circular references without escape paths

### 3. Toolbar Layout
- Group related items together
- Use separators (VSeparator) between groups
- Keep most important actions easily accessible

### 4. Selection Management
- Use single selection for mutually exclusive tools
- Use multiple selection for modifiers or filters
- Provide visual feedback for selected state

## Advanced Customization

### Custom Tooltip Content

Create fully custom tooltip content by extending Control:

```gdscript
class CustomTooltip extends Control:
	signal link_clicked(tooltip_id: String)
	
	func _ready() -> void:
		# Build custom UI
		var container = VBoxContainer.new()
		add_child(container)
		
		# Add any controls you want
		var image = TextureRect.new()
		container.add_child(image)
		
		var interactive_button = Button.new()
		interactive_button.pressed.connect(_on_button_pressed)
		container.add_child(interactive_button)
```

### Dynamic Tooltips

Update tooltips at runtime:

```gdscript
# Update tooltip content based on current state
func update_tool_tooltip() -> void:
	var brush_size = get_current_brush_size()
	toolbar.register_tooltip(
		"tool_brush",
		"Brush Tool",
		"Current size: " + str(brush_size) + "px",
		[]
	)
```

## File Structure

```
ToolbarItem.gd          # Base class for toolbar items
ActionItem.gd           # Action button implementation
SelectionItem.gd        # Selectable tool implementation
Toolbar.gd              # Main toolbar container
TooltipWindow.gd        # Floating tooltip display
TooltipContent.gd       # Tooltip content formatting
TooltipRegistry.gd      # Tooltip definition storage
ToolbarDemo.gd          # Basic usage example
AdvancedToolbarExample.gd  # Advanced features demo
```

## Future Enhancements

Potential additions:
- Icon support with better visual integration
- Keyboard shortcuts displayed in tooltips
- Tooltip search/filtering
- Tooltip history/bookmarks
- Custom animations for tooltip appearance
- Drag-and-drop toolbar customization
- Tooltip themes/styling system
