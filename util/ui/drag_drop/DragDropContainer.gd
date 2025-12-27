# DragDropContainer.gd
# A container that allows drag-and-drop reordering of its children
class_name DragDropContainer
extends Container

signal items_reordered(new_order: Array[Node])

enum Orientation {
	VERTICAL,
	HORIZONTAL
}

@export var orientation: DragDropContainer.Orientation = Orientation.VERTICAL
@export var spacing: int = 4
@export var drag_preview_modulate: Color = Color(1, 1, 1, 0.7)
@export var ghost_modulate: Color = Color(0.5, 0.5, 1.0, 0.5)

var _dragging_child: Control = null
var _drag_preview: Control = null
var _ghost_placeholder: Control = null
var _original_index: int = -1
var _current_drop_index: int = -1
var _original_positions: Array = []  # Cached positions at drag start

func _ready() -> void:
	# Make all children draggable
	_setup_children()
	child_entered_tree.connect(_on_child_added)

func _setup_children() -> void:
	for child in get_children():
		if child is Control and child != _ghost_placeholder:
			_make_draggable(child)

func _on_child_added(node: Node) -> void:
	if node is Control and node != _ghost_placeholder:
		_make_draggable(node)
		queue_sort()

func _make_draggable(control: Control) -> void:
	# Ensure the control can receive drag events
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect drag signals if not already connected
	if not control.gui_input.is_connected(_on_child_gui_input.bind(control)):
		control.gui_input.connect(_on_child_gui_input.bind(control))

func _on_child_gui_input(event: InputEvent, control: Control) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_drag(control)

func _start_drag(control: Control) -> void:
	_dragging_child = control
	_original_index = control.get_index()
	_current_drop_index = _original_index
	
	# Enable processing for global input
	set_process_input(true)
	
	# Cache original positions of all visible children BEFORE any changes
	_original_positions.clear()
	for child in get_children():
		if child is Control and child.visible:
			_original_positions.append({
				"node": child,
				"index": child.get_index(),
				"position": child.position,
				"size": child.size
			})
	
	# Create cursor-attached drag preview
	_drag_preview = _create_preview_control(control)
	get_tree().root.add_child(_drag_preview)
	_drag_preview.global_position = get_global_mouse_position() - _drag_preview.size / 2
	
	# Create ghost placeholder in the list
	_ghost_placeholder = _create_preview_control(control)
	_ghost_placeholder.modulate = ghost_modulate
	_ghost_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ghost_placeholder)
	move_child(_ghost_placeholder, _original_index)
	
	# Hide original during drag
	control.visible = false

func _create_preview_control(source: Control) -> Control:
	var preview = Panel.new()
	preview.size = source.size
	preview.custom_minimum_size = source.size
	preview.modulate = drag_preview_modulate
	
	# Try to copy visual content
	if source is Panel:
		# Copy children visually
		for child in source.get_children():
			var child_copy = _duplicate_node_visual(child)
			if child_copy != null:
				preview.add_child(child_copy)
	elif source is Label:
		var label = Label.new()
		label.text = source.text
		label.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
		label.position = Vector2(8, 8)
		preview.add_child(label)
	elif source is Button:
		var label = Label.new()
		label.text = source.text
		label.position = Vector2(8, 8)
		preview.add_child(label)
	
	return preview

func _duplicate_node_visual(node: Node) -> Node:
	if node is Label:
		var label = Label.new()
		label.text = node.text
		label.position = node.position
		label.size = node.size
		if node.has_method("get_theme_font_size"):
			label.add_theme_font_size_override("font_size", node.get_theme_font_size("font_size"))
		return label
	elif node is HBoxContainer or node is VBoxContainer:
		var container = null
		if node is HBoxContainer:
			container = HBoxContainer.new()
		else:
			container = VBoxContainer.new()
		container.position = node.position
		container.size = node.size
		for child in node.get_children():
			var child_copy = _duplicate_node_visual(child)
			if child_copy != null:
				container.add_child(child_copy)
		return container
	return null

func _end_drag() -> void:
	if _dragging_child == null:
		return
	print("Stopped drag, reordering item from "+str(_original_index)+" to "+str(_current_drop_index))
	# Disable processing for global input
	set_process_input(false)
	
	# Remove preview
	if _drag_preview != null:
		_drag_preview.queue_free()
		_drag_preview = null
	
	# Show original
	_dragging_child.visible = true
	
	# Perform reorder if drop index is different
	if _current_drop_index != -1 and _current_drop_index != _original_index:
		_reorder_child(_original_index, _current_drop_index)
	
	# Remove ghost placeholder
	if _ghost_placeholder != null:
		_ghost_placeholder.queue_free()
		_ghost_placeholder = null
	
	_dragging_child = null
	_original_index = -1
	_current_drop_index = -1
	_original_positions.clear()
	
	queue_sort()

func _input(event: InputEvent) -> void:
	# Handle global mouse release to end drag
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if _dragging_child != null:
				_end_drag()
				get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if _dragging_child == null or _drag_preview == null:
		return
	
	# Update cursor-attached preview position
	_drag_preview.global_position = get_global_mouse_position() - _drag_preview.size / 2
	
	# Calculate new drop index
	var new_drop_index = _calculate_drop_index()
	
	# Only update if it actually changed to prevent flickering
	if new_drop_index != _current_drop_index and new_drop_index != -1:
		_current_drop_index = new_drop_index
		if _ghost_placeholder != null:
			move_child(_ghost_placeholder, _current_drop_index)
		queue_sort()

func _calculate_drop_index() -> int:
	var mouse_pos = get_local_mouse_position()
	
	# Use the cached original positions, not current positions
	var visible_items: Array = []
	for item in _original_positions:
		# Skip the item we're dragging
		if item.node == _dragging_child:
			continue
		visible_items.append(item)
	
	if visible_items.is_empty():
		return 0
	
	# Determine insertion index based on mouse position relative to original positions
	var best_index = -1
	
	for i in range(visible_items.size()):
		var item = visible_items[i]
		var item_rect = Rect2(item.position, item.size)
		var midpoint: float
		var mouse_test: float
		
		if orientation == Orientation.VERTICAL:
			midpoint = item_rect.position.y + item_rect.size.y / 2
			mouse_test = mouse_pos.y
		else:
			midpoint = item_rect.position.x + item_rect.size.x / 2
			mouse_test = mouse_pos.x
		
		# If mouse is before the midpoint of this item, insert here
		if mouse_test < midpoint:
			best_index = item.index
			break
	
	# If no item was found (mouse is after all items), insert at end
	if best_index == -1:
		# Find the last non-dragging item's index and add 1
		if not visible_items.is_empty():
			best_index = visible_items[-1].index + 1
		else:
			best_index = 0
	
	return best_index

func _reorder_child(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	
	# Get the actual child at the original index (accounting for ghost being there)
	var child = _dragging_child
	var ghost_index = _ghost_placeholder.get_index()
	
	# Calculate the correct target index
	# The ghost shows where we want to insert, but we need to account for:
	# 1. The ghost itself being in the list
	# 2. The original child being removed
	var adjusted_to_index = to_index
	
	# If ghost is before the original position, the target is correct
	# If ghost is after the original position, we need to subtract 1 because
	# removing the original will shift everything down
	if ghost_index > from_index:
		adjusted_to_index = ghost_index - 1
	else:
		adjusted_to_index = ghost_index
	
	print("Moving child from actual index " + str(from_index) + " to " + str(adjusted_to_index))
	move_child(child, adjusted_to_index)
	
	# Emit reorder signal
	var ordered_children: Array[Node] = []
	for c in get_children():
		if c is Control and c != _ghost_placeholder:
			ordered_children.append(c)
	
	items_reordered.emit(ordered_children)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_arrange_children()

func _arrange_children() -> void:
	var offset: float = 0
	var children = get_children()
	
	for child in children:
		if not child is Control:
			continue
		
		# Skip invisible children (but not ghost)
		if not child.visible and child != _ghost_placeholder:
			continue
		
		# Position based on orientation
		if orientation == Orientation.VERTICAL:
			child.position = Vector2(0, offset)
			child.size.x = size.x
			offset += child.size.y + spacing
		else:
			child.position = Vector2(offset, 0)
			child.size.y = size.y
			offset += child.size.x + spacing

func _get_minimum_size() -> Vector2:
	var min_size := Vector2.ZERO
	var total_size: float = 0
	var max_cross_size: float = 0
	var visible_count: int = 0
	
	for child in get_children():
		if not child is Control:
			continue
		
		# Count ghost but not hidden dragging child
		if not child.visible and child != _ghost_placeholder:
			continue
		
		var child_min = child.get_combined_minimum_size()
		
		if orientation == Orientation.VERTICAL:
			total_size += child_min.y
			max_cross_size = max(max_cross_size, child_min.x)
		else:
			total_size += child_min.x
			max_cross_size = max(max_cross_size, child_min.y)
		
		visible_count += 1
	
	# Add spacing
	if visible_count > 0:
		total_size += spacing * (visible_count - 1)
	
	if orientation == Orientation.VERTICAL:
		min_size = Vector2(max_cross_size, total_size)
	else:
		min_size = Vector2(total_size, max_cross_size)
	
	return min_size
