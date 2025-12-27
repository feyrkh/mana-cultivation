# DraggableCamera2DDemo.gd
# Demonstrates the DraggableCamera2D control with multiple cameras and content
extends Control

var camera1: DraggableCamera2D
var camera2: DraggableCamera2D

func _ready() -> void:
	# Create demo layout
	var main_container = HBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Left side - Camera 1 with grid content
	var left_panel = _create_camera_panel("Research Board Camera", Color(0.2, 0.3, 0.4))
	camera1 = left_panel.camera
	main_container.add_child(left_panel.panel)
	
	# Right side - Camera 2 with different content
	var right_panel = _create_camera_panel("Spell Visualization Camera", Color(0.3, 0.2, 0.4))
	camera2 = right_panel.camera
	main_container.add_child(right_panel.panel)
	
	# Configure cameras with different settings
	camera1.min_zoom = 0.5
	camera1.max_zoom = 3.0
	camera1.set_bounds(Rect2(-5000, -5000, 10000, 10000))
	
	camera2.min_zoom = 0.25
	camera2.max_zoom = 5.0
	camera2.set_bounds(Rect2(-8000, -8000, 16000, 16000))
	
	# Connect signals for debug info
	camera1.zoom_changed.connect(_on_camera1_zoom_changed)
	camera1.position_changed.connect(_on_camera1_position_changed)
	
	camera2.zoom_changed.connect(_on_camera2_zoom_changed)
	camera2.position_changed.connect(_on_camera2_position_changed)
	await get_tree().process_frame
	_populate_grid_content(camera1, 5, 5)
	_populate_circle_content(camera2)
	print("Camera Demo Ready!")
	print("- Use mouse wheel to zoom")
	print("- Middle mouse button to pan")
	print("- Each camera has independent zoom and position")

func _create_camera_panel(title: String, color: Color) -> Dictionary:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Title
	var label = Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Camera container
	var camera = DraggableCamera2D.new()
	camera.custom_minimum_size = Vector2(400, 400)
	camera.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(camera)
	
	# Add background color to camera
	var background = ColorRect.new()
	background.color = color
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera.add_child(background)
	camera.move_child(background, 0)  # Behind content container
	
	# Info label
	var info = Label.new()
	info.text = "Zoom: 1.00x | Pos: (0, 0)"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.name = "InfoLabel"
	vbox.add_child(info)
	
	return {"panel": panel, "camera": camera, "info": info}

func _populate_grid_content(camera: DraggableCamera2D, rows: int, cols: int) -> void:
	# Create a grid of tiles representing a research board
	var tile_size = 80
	var spacing = 10
	
	for row in range(rows):
		for col in range(cols):
			var tile = _create_tile(
				Vector2(col * (tile_size + spacing), row * (tile_size + spacing)),
				Vector2(tile_size, tile_size),
				"Tile %d,%d" % [row, col],
				_get_random_tile_color()
			)
			camera.add_content(tile)
	
	# Add center marker
	var center_marker = _create_tile(
		Vector2(-20, -20),
		Vector2(40, 40),
		"CENTER",
		Color.RED
	)
	camera.add_content(center_marker)

func _populate_circle_content(camera: DraggableCamera2D) -> void:
	# Create a circular pattern of nodes
	var radius = 300
	var count = 12
	
	for i in range(count):
		var angle = (i / float(count)) * TAU
		var pos = Vector2(cos(angle), sin(angle)) * radius
		
		var node = _create_tile(
			pos - Vector2(40, 40),
			Vector2(80, 80),
			"Node %d" % i,
			Color.from_hsv(i / float(count), 0.7, 0.9)
		)
		camera.add_content(node)
	
	# Add center marker
	var center_marker = _create_tile(
		Vector2(-30, -30),
		Vector2(60, 60),
		"ORIGIN",
		Color.YELLOW
	)
	camera.add_content(center_marker)

func _create_tile(pos: Vector2, tile_size: Vector2, label_text: String, color: Color) -> Control:
	var panel = PanelContainer.new()
	panel.position = pos
	panel.custom_minimum_size = tile_size
	
	# Style
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = color
	stylebox.border_color = Color.WHITE
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", stylebox)
	
	# Label
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	return panel

func _get_random_tile_color() -> Color:
	var colors = [
		Color(0.4, 0.6, 0.8),  # Blue
		Color(0.6, 0.8, 0.4),  # Green
		Color(0.8, 0.6, 0.4),  # Orange
		Color(0.7, 0.5, 0.8),  # Purple
		Color(0.8, 0.8, 0.5),  # Yellow
	]
	return colors[randi() % colors.size()]

func _on_camera1_zoom_changed(new_zoom: float) -> void:
	_update_info_label(camera1)

func _on_camera1_position_changed(new_position: Vector2) -> void:
	_update_info_label(camera1)


func _on_camera2_zoom_changed(new_zoom: float) -> void:
	_update_info_label(camera2)

func _on_camera2_position_changed(new_position: Vector2) -> void:
	_update_info_label(camera2)

func _update_info_label(camera: DraggableCamera2D) -> void:
	# Find the info label in the same panel
	var parent = camera.get_parent()
	if parent != null:
		var info_label = parent.get_node_or_null("InfoLabel")
		if info_label != null:
			info_label.text = "Zoom: %.2fx | Pos: (%.0f, %.0f)" % [
				camera.get_zoom(),
				camera.get_camera_position().x,
				camera.get_camera_position().y
			]
