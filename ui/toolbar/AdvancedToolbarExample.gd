# AdvancedToolbarExample.gd
# Shows more advanced features like custom tooltip content and dynamic updates
extends Control

@onready var toolbar: Toolbar
@onready var info_panel: VBoxContainer

func _ready() -> void:
	_setup_ui()
	_setup_advanced_toolbar()

func _setup_ui() -> void:
	var main = VBoxContainer.new()
	main.anchor_right = 1.0
	main.anchor_bottom = 1.0
	add_child(main)
	
	var title = Label.new()
	title.text = "Advanced Toolbar Example"
	title.add_theme_font_size_override("font_size", 20)
	main.add_child(title)
	
	info_panel = VBoxContainer.new()
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(info_panel)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(spacer)
	
	# Toolbar at bottom
	var toolbar_panel = PanelContainer.new()
	toolbar_panel.custom_minimum_size = Vector2(0, 60)
	main.add_child(toolbar_panel)
	
	toolbar = Toolbar.new()
	toolbar.anchor_right = 1.0
	toolbar.anchor_bottom = 1.0
	toolbar_panel.add_child(toolbar)

func _setup_advanced_toolbar() -> void:
	# Example 1: Multiple selection mode
	toolbar.allow_multiple_selection = true
	
	# Register complex tooltip network
	toolbar.register_tooltip(
		"mode_normal",
		"Normal Mode",
		"Standard editing mode with full access to all tools and features.",
		[
			{"text": "Quick Mode", "tooltip_id": "mode_quick"},
			{"text": "Advanced Mode", "tooltip_id": "mode_advanced"}
		]
	)
	
	toolbar.register_tooltip(
		"mode_quick",
		"Quick Mode",
		"Streamlined interface for rapid editing. Some advanced features are hidden.",
		[
			{"text": "Normal Mode", "tooltip_id": "mode_normal"},
			{"text": "What's Hidden?", "tooltip_id": "mode_quick_details"}
		]
	)
	
	toolbar.register_tooltip(
		"mode_quick_details",
		"Quick Mode Details",
		"Hidden features: Layer effects, advanced selection tools, custom brushes.",
		[
			{"text": "Back to Quick Mode", "tooltip_id": "mode_quick"}
		]
	)
	
	toolbar.register_tooltip(
		"mode_advanced",
		"Advanced Mode",
		"Power user mode with additional panels and experimental features.",
		[
			{"text": "Normal Mode", "tooltip_id": "mode_normal"},
			{"text": "Experimental Features", "tooltip_id": "mode_advanced_experimental"}
		]
	)
	
	toolbar.register_tooltip(
		"mode_advanced_experimental",
		"Experimental Features",
		"These features are still in development: AI-assisted drawing, 3D layer support, real-time collaboration."
	)
	
	# Add items
	toolbar.add_selection_item("mode_normal", "Normal", null, "mode_normal")
	toolbar.add_selection_item("mode_quick", "Quick", null, "mode_quick")
	toolbar.add_selection_item("mode_advanced", "Advanced", null, "mode_advanced")
	
	# Add action for testing
	toolbar.add_action_item("refresh", "Refresh", null)
	
	# Connect signals
	toolbar.action_triggered.connect(_on_action)
	toolbar.selection_changed.connect(_on_selection)
	
	_update_info_panel()

func _on_action(item_id: String) -> void:
	var label = Label.new()
	label.text = "Action: " + item_id
	info_panel.add_child(label)

func _on_selection(item_id: String) -> void:
	_update_info_panel()

func _update_info_panel() -> void:
	# Clear
	for child in info_panel.get_children():
		child.queue_free()
	
	# Show current selection
	var title = Label.new()
	title.text = "Current Modes:"
	title.add_theme_font_size_override("font_size", 16)
	info_panel.add_child(title)
	
	var selected = toolbar.get_selected_items()
	if selected.is_empty():
		var none = Label.new()
		none.text = "No modes selected"
		info_panel.add_child(none)
	else:
		for item in selected:
			var mode_label = Label.new()
			mode_label.text = "• " + item.item_id
			info_panel.add_child(mode_label)


# ============================================
# Example: Custom tooltip content
# ============================================

class CustomTooltipContent extends Control:
	signal link_clicked(tooltip_id: String)
	
	func _ready() -> void:
		# Create custom UI
		var container = VBoxContainer.new()
		add_child(container)
		
		var title = Label.new()
		title.text = "Custom Tooltip"
		title.add_theme_font_size_override("font_size", 16)
		container.add_child(title)
		
		# Add an image preview
		var image_rect = ColorRect.new()
		image_rect.color = Color.BLUE
		image_rect.custom_minimum_size = Vector2(100, 100)
		container.add_child(image_rect)
		
		# Add interactive elements
		var button = Button.new()
		button.text = "Click me!"
		button.pressed.connect(_on_button_pressed)
		container.add_child(button)
	
	func _on_button_pressed() -> void:
		print("Custom tooltip button clicked!")


# ============================================
# Example: Dynamic tooltip updates
# ============================================

func example_dynamic_tooltip_updates():
	# You can update tooltips on the fly
	var counter = 0
	
	var update_tooltip = func():
		counter += 1
		toolbar.register_tooltip(
			"dynamic_item",
			"Dynamic Content",
			"This tooltip has been updated " + str(counter) + " times!",
			[]
		)
	
	# Update every second
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(update_tooltip)
	add_child(timer)
	timer.start()
