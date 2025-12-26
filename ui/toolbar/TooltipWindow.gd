# TooltipWindow.gd
# A floating tooltip window that can contain links to nested tooltips
class_name TooltipWindow
extends PanelContainer

signal tooltip_link_clicked(tooltip_id: String)
signal window_closed()

var tooltip_id: String = ""
var is_locked: bool = false
var anchor_item: Control = null
var preferred_direction: Vector2 = Vector2.UP  # Direction to place tooltip relative to anchor

@onready var content_container: VBoxContainer
@onready var close_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_ui()

func _setup_ui() -> void:
	if content_container:
		return
	content_container = VBoxContainer.new()
	add_child(content_container)
	
	# Close button (only visible when locked)
	close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(20, 20)
	close_button.visible = false
	close_button.pressed.connect(_on_close_button_pressed)
	content_container.add_child(close_button)

func set_content(content: Control) -> void:
	# Clear existing content (except close button)
	if !content_container:
		_setup_ui()
	for child in content_container.get_children():
		if child != close_button:
			child.queue_free()
	
	# Add new content
	content_container.add_child(content)
	content_container.move_child(close_button, 0)  # Keep close button on top

func set_locked(locked: bool) -> void:
	_setup_ui()
	is_locked = locked
	close_button.visible = locked
	await get_tree().process_frame
	position_relative_to_anchor(get_viewport().get_visible_rect().size)
	# Change visual appearance when locked
	if locked:
		modulate = Color(1.0, 1.0, 0.9)  # Slight yellow tint
	else:
		modulate = Color.WHITE

func position_relative_to_anchor(viewport_size: Vector2) -> void:
	if anchor_item == null:
		return
	
	# Get anchor global position and size
	var anchor_global_pos = anchor_item.global_position
	var anchor_size = anchor_item.size
	
	# Calculate desired position based on preferred direction
	var desired_pos: Vector2
	var tooltip_size = size
	
	# Try preferred direction first
	if preferred_direction.y < 0:  # UP
		desired_pos = Vector2(
			anchor_global_pos.x + anchor_size.x / 2 - tooltip_size.x / 2,
			anchor_global_pos.y - tooltip_size.y - 8
		)
	elif preferred_direction.y > 0:  # DOWN
		desired_pos = Vector2(
			anchor_global_pos.x + anchor_size.x / 2 - tooltip_size.x / 2,
			anchor_global_pos.y + anchor_size.y + 8
		)
	elif preferred_direction.x < 0:  # LEFT
		desired_pos = Vector2(
			anchor_global_pos.x - tooltip_size.x - 8,
			anchor_global_pos.y + anchor_size.y / 2 - tooltip_size.y / 2
		)
	else:  # RIGHT
		desired_pos = Vector2(
			anchor_global_pos.x + anchor_size.x + 8,
			anchor_global_pos.y + anchor_size.y / 2 - tooltip_size.y / 2
		)
	
	# Constrain to viewport bounds
	desired_pos.x = clamp(desired_pos.x, 0, viewport_size.x - tooltip_size.x)
	desired_pos.y = clamp(desired_pos.y, 0, viewport_size.y - tooltip_size.y)
	
	# Final check: ensure tooltip doesn't overlap anchor
	var tooltip_rect = Rect2(desired_pos, tooltip_size)
	var anchor_rect = Rect2(anchor_global_pos, anchor_size)
	
	if tooltip_rect.intersects(anchor_rect):
		# If preferred direction causes overlap, try opposite direction
		if preferred_direction.y < 0:  # Was UP, try DOWN
			desired_pos.y = anchor_global_pos.y + anchor_size.y + 8
		elif preferred_direction.y > 0:  # Was DOWN, try UP
			desired_pos.y = anchor_global_pos.y - tooltip_size.y - 8
		elif preferred_direction.x < 0:  # Was LEFT, try RIGHT
			desired_pos.x = anchor_global_pos.x + anchor_size.x + 8
		else:  # Was RIGHT, try LEFT
			desired_pos.x = anchor_global_pos.x - tooltip_size.x - 8
		
		# Constrain again
		desired_pos.x = clamp(desired_pos.x, 0, viewport_size.x - tooltip_size.x)
		desired_pos.y = clamp(desired_pos.y, 0, viewport_size.y - tooltip_size.y)
	
	global_position = desired_pos

func _on_close_button_pressed() -> void:
	window_closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if not is_locked:
		return
	
	# Allow clicking outside to close when locked
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var local_pos = get_local_mouse_position()
			var rect = Rect2(Vector2.ZERO, size)
			if not rect.has_point(local_pos):
				window_closed.emit()
				queue_free()
