# Camera2D.gd
# A Control-based camera that supports zooming, panning, and bounded viewport
class_name DraggableCamera2D
extends Control

signal zoom_changed(new_zoom: float)
signal position_changed(new_position: Vector2)

# Zoom configuration
@export var min_zoom: float = 0.25
@export var max_zoom: float = 4.0
@export var zoom_speed: float = 0.1
@export var zoom_smoothing: float = 0.3  # How much to reduce zoom increments near extremes

# Pan configuration
@export var pan_button: MouseButton = MOUSE_BUTTON_MIDDLE
@export var enable_pan: bool = true

# Bounds configuration
@export var enable_bounds: bool = true
@export var bounds_rect: Rect2 = Rect2(-1000, -1000, 2000, 2000)
@export var bounds_elasticity: float = 5.0  # Speed of return to bounds
@export var bounds_margin: float = 50.0  # Extra margin before forcing return

# Camera state
var camera_zoom: float = 1.0
var camera_position: Vector2 = Vector2.ZERO  # Center of the viewport

# Internal state
var _is_panning: bool = false
var _pan_start_pos: Vector2 = Vector2.ZERO
var _pan_start_camera_pos: Vector2 = Vector2.ZERO
var _content_container: Control = null
var _out_of_bounds: bool = false

func _init() -> void:
	# Create content container immediately so it's available for add_content()
	_content_container = Control.new()
	_content_container.name = "ContentContainer"
	_content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Set mouse filter to pass so we can handle input even when content is under cursor
	mouse_filter = Control.MOUSE_FILTER_PASS

func _ready() -> void:
	# Add the content container to the scene tree
	add_child(_content_container)
	
	# Enable clipping to prevent content from overlapping other views
	clip_contents = true
	
	await get_tree().process_frame
	# Set up initial transform
	_update_transform()
	
	# Enable processing
	set_process(true)
	set_process_input(true)

func _gui_input(event: InputEvent) -> void:
	# Handle zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at_point(get_local_mouse_position(), 1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at_point(get_local_mouse_position(), -1)
			accept_event()

func _input(event: InputEvent) -> void:
	# Handle pan button
	if event is InputEventMouseButton:
		if event.button_index == pan_button and enable_pan:
			if event.pressed:
				# Only start pan if mouse is over this camera
				var mouse_pos = get_global_mouse_position()
				var rect = get_global_rect()
				if rect.has_point(mouse_pos):
					_start_pan(get_local_mouse_position())
					get_viewport().set_input_as_handled()
			else:
				# Always end pan on release (even if mouse is outside window)
				if _is_panning:
					_end_pan()
					get_viewport().set_input_as_handled()

	# Handle pan drag
	elif event is InputEventMouseMotion and _is_panning:
		_update_pan(get_local_mouse_position())
		get_viewport().set_input_as_handled()

func _end_drag() -> void:
	# This was in the old _input handler, keep it for compatibility
	_end_pan()

func _process(delta: float) -> void:
	# Apply bounds correction if needed
	if enable_bounds and _out_of_bounds:
		_apply_bounds_correction(delta)

func _zoom_at_point(screen_point: Vector2, direction: int) -> void:
	# Calculate dynamic zoom increment based on proximity to extremes
	var zoom_range = max_zoom - min_zoom
	var zoom_from_min = camera_zoom - min_zoom
	var zoom_from_max = max_zoom - camera_zoom
	
	# Normalize distances to [0, 1]
	var normalized_from_min = zoom_from_min / zoom_range
	var normalized_from_max = zoom_from_max / zoom_range
	
	# Calculate smoothing factor (smaller near extremes)
	var smoothing_factor: float
	if direction > 0:  # Zooming in
		smoothing_factor = normalized_from_max
	else:  # Zooming out
		smoothing_factor = normalized_from_min
	
	# Apply smoothing curve (quadratic for smoother feel)
	smoothing_factor = 1.0 - (1.0 - smoothing_factor) * zoom_smoothing
	smoothing_factor = max(0.1, smoothing_factor)  # Minimum 10% speed
	
	# Calculate zoom increment
	var zoom_increment = zoom_speed * smoothing_factor * direction
	
	# Get world position before zoom
	var world_pos_before = _screen_to_world(screen_point)
	
	# Apply zoom
	var old_zoom = camera_zoom
	camera_zoom = clamp(camera_zoom + zoom_increment, min_zoom, max_zoom)
	
	if abs(camera_zoom - old_zoom) < 0.001:
		return  # No actual change
	
	# Get world position after zoom
	var world_pos_after = _screen_to_world(screen_point)
	
	# Adjust camera position to keep the point under cursor
	camera_position += world_pos_before - world_pos_after
	
	_update_transform()
	zoom_changed.emit(camera_zoom)
	position_changed.emit(camera_position)
	
	_check_bounds()

func _start_pan(screen_pos: Vector2) -> void:
	_is_panning = true
	_pan_start_pos = screen_pos
	_pan_start_camera_pos = camera_position
	#print("Starting pan at screen_pos=%s and camera_pos=%s" % [screen_pos, camera_position])

func _update_pan(screen_pos: Vector2) -> void:
	if not _is_panning:
		return
	# Calculate delta in screen space
	var screen_delta = screen_pos - _pan_start_pos
	# Convert to world space delta (inverted because we're moving the camera)
	var world_delta = screen_delta / camera_zoom
	#print("Screen delta: %s = %s - %s" % [screen_delta, screen_pos, _pan_start_pos])
	#print("World delta: %s = %s / %s" % [world_delta, screen_delta, camera_zoom])
	
	# Update camera position
	camera_position = _pan_start_camera_pos - world_delta
	
	_update_transform()
	position_changed.emit(camera_position)
	
	_check_bounds()

func _end_pan() -> void:
	_is_panning = false

func _update_transform() -> void:
	if _content_container == null:
		return
	
	# Calculate the offset to center the camera position
	var viewport_center = size / 2.0
	var world_offset = camera_position * camera_zoom
	var offset = viewport_center - world_offset
	
	# Apply scale and position to content container
	_content_container.scale = Vector2.ONE * camera_zoom
	_content_container.position = offset

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	# Convert screen position to world position
	var viewport_center = size / 2.0
	var offset_from_center = screen_pos - viewport_center
	return camera_position + offset_from_center / camera_zoom

func _world_to_screen(world_pos: Vector2) -> Vector2:
	# Convert world position to screen position
	var viewport_center = size / 2.0
	var offset_from_camera = (world_pos - camera_position) * camera_zoom
	return viewport_center + offset_from_camera

func _check_bounds() -> void:
	if not enable_bounds:
		_out_of_bounds = false
		return
	
	# Calculate current viewport bounds in world space
	var viewport_half_size = (size / camera_zoom) / 2.0
	var viewport_min = camera_position - viewport_half_size
	var viewport_max = camera_position + viewport_half_size
	
	# Check if viewport extends beyond bounds (with margin)
	var margin_world = bounds_margin / camera_zoom
	
	_out_of_bounds = (
		viewport_min.x < bounds_rect.position.x - margin_world or
		viewport_min.y < bounds_rect.position.y - margin_world or
		viewport_max.x > bounds_rect.end.x + margin_world or
		viewport_max.y > bounds_rect.end.y + margin_world
	)

func _apply_bounds_correction(delta: float) -> void:
	# Calculate current viewport bounds in world space
	var viewport_half_size = (size / camera_zoom) / 2.0
	var viewport_min = camera_position - viewport_half_size
	var viewport_max = camera_position + viewport_half_size
	
	var correction = Vector2.ZERO

	# Calculate corrections for each axis
	# If viewport exceeds bounds on both sides, center on that axis
	var exceeds_left = viewport_min.x < bounds_rect.position.x
	var exceeds_right = viewport_max.x > bounds_rect.end.x
	var exceeds_top = viewport_min.y < bounds_rect.position.y
	var exceeds_bottom = viewport_max.y > bounds_rect.end.y

	if exceeds_left and exceeds_right:
		# Viewport larger than bounds - center horizontally
		var bounds_center_x = bounds_rect.position.x + bounds_rect.size.x / 2.0
		correction.x = bounds_center_x - camera_position.x
	elif exceeds_left:
		correction.x = bounds_rect.position.x - viewport_min.x
	elif exceeds_right:
		correction.x = bounds_rect.end.x - viewport_max.x

	if exceeds_top and exceeds_bottom:
		# Viewport larger than bounds - center vertically
		var bounds_center_y = bounds_rect.position.y + bounds_rect.size.y / 2.0
		correction.y = bounds_center_y - camera_position.y
	elif exceeds_top:
		correction.y = bounds_rect.position.y - viewport_min.y
	elif exceeds_bottom:
		correction.y = bounds_rect.end.y - viewport_max.y
	
	# Apply correction smoothly
	if correction.length() > 0.01:
		camera_position += correction * bounds_elasticity * delta
		_update_transform()
		position_changed.emit(camera_position)
	else:
		_out_of_bounds = false

# Public API methods

func set_zoom(new_zoom: float, screen_point: Vector2 = size / 2.0) -> void:
	"""Set zoom level, optionally keeping a specific screen point stable"""
	var world_pos_before = _screen_to_world(screen_point)
	
	camera_zoom = clamp(new_zoom, min_zoom, max_zoom)
	
	var world_pos_after = _screen_to_world(screen_point)
	camera_position += world_pos_before - world_pos_after
	
	_update_transform()
	zoom_changed.emit(camera_zoom)
	position_changed.emit(camera_position)
	_check_bounds()

func set_camera_position(new_position: Vector2) -> void:
	"""Set camera position (center of viewport)"""
	camera_position = new_position
	_update_transform()
	position_changed.emit(camera_position)
	_check_bounds()

func get_zoom() -> float:
	return camera_zoom

func get_camera_position() -> Vector2:
	return camera_position

func add_content(node: Node) -> void:
	"""Add a node to the camera's content container"""
	if _content_container != null:
		_content_container.add_child(node)

func remove_content(node: Node) -> void:
	"""Remove a node from the camera's content container"""
	if _content_container != null and node.get_parent() == _content_container:
		_content_container.remove_child(node)

func get_content_container() -> Control:
	"""Get the container that holds camera content"""
	return _content_container

func set_bounds(new_bounds: Rect2) -> void:
	"""Update the bounds rectangle"""
	bounds_rect = new_bounds
	_check_bounds()

func get_viewport_rect_world() -> Rect2:
	"""Get the current viewport rectangle in world coordinates"""
	var viewport_half_size = (size / camera_zoom) / 2.0
	return Rect2(
		camera_position - viewport_half_size,
		size / camera_zoom
	)
