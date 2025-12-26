# ToolbarDemo.gd
# Comprehensive demo of the toolbar system
extends Control

@onready var toolbar: Toolbar
@onready var output_label: Label
@onready var selection_label: Label

func _ready() -> void:
	_setup_ui()
	_setup_toolbar()

func _setup_ui() -> void:
	# Create main layout
	var main_container = VBoxContainer.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	add_child(main_container)
	
	# Title
	var title = Label.new()
	title.text = "Toolbar System Demo"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Hover over items to see tooltips. Press TAB to lock a tooltip. Click links in tooltips to open nested tooltips."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(instructions)
	
	main_container.add_child(HSeparator.new())
	
	# Output label
	output_label = Label.new()
	output_label.text = "Action output will appear here"
	output_label.add_theme_font_size_override("font_size", 14)
	main_container.add_child(output_label)
	
	# Selection label
	selection_label = Label.new()
	selection_label.text = "No selection"
	selection_label.add_theme_font_size_override("font_size", 14)
	main_container.add_child(selection_label)
	
	main_container.add_child(HSeparator.new())
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(spacer)
	
	# Toolbar container at bottom
	var toolbar_panel = PanelContainer.new()
	toolbar_panel.custom_minimum_size = Vector2(0, 80)
	main_container.add_child(toolbar_panel)
	
	toolbar = Toolbar.new()
	toolbar.anchor_right = 1.0
	toolbar.anchor_bottom = 1.0
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar_panel.add_child(toolbar)
	
	# Connect signals
	toolbar.action_triggered.connect(_on_action_triggered)
	toolbar.selection_changed.connect(_on_selection_changed)

func _setup_toolbar() -> void:
	# Register tooltips with nested links
	toolbar.register_tooltip(
		"tool_pencil",
		"Pencil Tool",
		"Draw freehand lines and shapes. Adjust brush size and opacity in the properties panel.",
		[
			{"text": "Brush Settings", "tooltip_id": "settings_brush"},
			{"text": "Keyboard Shortcuts", "tooltip_id": "shortcuts_drawing"}
		]
	)
	
	toolbar.register_tooltip(
		"tool_eraser",
		"Eraser Tool",
		"Remove parts of your drawing. The eraser respects layer boundaries.",
		[
			{"text": "Layer Info", "tooltip_id": "info_layers"}
		]
	)
	
	toolbar.register_tooltip(
		"tool_select",
		"Selection Tool",
		"Select areas of your canvas. Use Shift to add to selection, Alt to subtract.",
		[
			{"text": "Selection Modes", "tooltip_id": "modes_selection"}
		]
	)
	
	toolbar.register_tooltip(
		"action_save",
		"Save",
		"Save your current work to disk. Use Ctrl+S for quick save."
	)
	
	toolbar.register_tooltip(
		"action_undo",
		"Undo",
		"Undo the last action. You can undo up to 50 actions."
	)
	
	toolbar.register_tooltip(
		"action_redo",
		"Redo",
		"Redo a previously undone action."
	)
	
	# Nested tooltip definitions
	toolbar.register_tooltip(
		"settings_brush",
		"Brush Settings",
		"Customize your brush size (1-100px), opacity (0-100%), and hardness (0-100%).",
		[
			{"text": "Back to Pencil", "tooltip_id": "tool_pencil"}
		]
	)
	
	toolbar.register_tooltip(
		"shortcuts_drawing",
		"Drawing Shortcuts",
		"B = Brush, E = Eraser, V = Selection, [ = Decrease Size, ] = Increase Size",
		[
			{"text": "All Shortcuts", "tooltip_id": "shortcuts_all"}
		]
	)
	
	toolbar.register_tooltip(
		"shortcuts_all",
		"All Keyboard Shortcuts",
		"Ctrl+Z = Undo, Ctrl+Y = Redo, Ctrl+S = Save, Ctrl+N = New, Ctrl+O = Open"
	)
	
	toolbar.register_tooltip(
		"info_layers",
		"Layer System",
		"Layers allow you to organize your drawing. Each layer can have different blend modes and opacity."
	)
	
	toolbar.register_tooltip(
		"modes_selection",
		"Selection Modes",
		"Rectangle: Drag to select rectangular area. Lasso: Draw freehand selection. Magic Wand: Select similar colors."
	)
	
	# Add selection items (tools)
	var pencil = toolbar.add_selection_item("tool_pencil", "Pencil", null, "tool_pencil")
	var eraser = toolbar.add_selection_item("tool_eraser", "Eraser", null, "tool_eraser")
	var select = toolbar.add_selection_item("tool_select", "Select", null, "tool_select")
	
	# Set default selection
	pencil.set_selected(true)
	toolbar.selected_items.append(pencil)
	
	# Add a separator
	add_toolbar_separator()
	
	# Add action items
	toolbar.add_action_item("action_save", "Save", null, "action_save")
	toolbar.add_action_item("action_undo", "Undo", null, "action_undo")
	toolbar.add_action_item("action_redo", "Redo", null, "action_redo")

func add_toolbar_separator() -> void:
	var separator = VSeparator.new()
	separator.custom_minimum_size = Vector2(20, 0)
	toolbar.add_child(separator)

func _on_action_triggered(item_id: String) -> void:
	output_label.text = "Action triggered: " + item_id
	print("Action: " + item_id)

func _on_selection_changed(item_id: String) -> void:
	var selected = toolbar.get_selected_item()
	if selected != null:
		selection_label.text = "Selected: " + selected.item_id
	else:
		selection_label.text = "No selection"
	print("Selection changed: " + item_id)
