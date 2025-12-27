# Toolbar.gd
# Main toolbar that manages items, selection, and tooltips
class_name Toolbar
extends HBoxContainer

signal action_triggered(item_id: String)
signal selection_changed(item_id: String)

enum TooltipDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@export var tooltip_direction: TooltipDirection = TooltipDirection.UP
@export var allow_multiple_selection: bool = false

var tooltip_registry: TooltipRegistry = TooltipRegistry.new()
var current_tooltip: TooltipWindow = null
var tooltip_stack: Array[TooltipWindow] = []  # Stack of locked tooltips
var hovered_item: ToolbarItem = null
var hover_timer: Timer = null
var selected_items: Array[SelectionItem] = []

func _ready() -> void:
	# Setup hover timer
	hover_timer = Timer.new()
	hover_timer.wait_time = 0.3  # 300ms delay before showing tooltip
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)

func _input(event: InputEvent) -> void:
	# Check for lock action (Tab key or ui_lock)
	if event.is_action_pressed("ui_lock") or (event is InputEventKey and event.keycode == KEY_TAB and event.pressed):
		if current_tooltip != null and not current_tooltip.is_locked:
			_lock_current_tooltip()
			get_viewport().set_input_as_handled()

# ============================================
# Item Management
# ============================================

func add_action_item(item_id: String, text: String, icon: Texture2D = null, tooltip_id: String = "") -> ActionItem:
	var item = ActionItem.new()
	item.item_id = item_id
	item.item_text = text
	item.icon = icon
	item.tooltip_id = tooltip_id
	item.action_triggered.connect(_on_action_item_triggered)
	add_child(item)
	return item

func add_selection_item(item_id: String, text: String, icon: Texture2D = null, tooltip_id: String = "") -> SelectionItem:
	var item = SelectionItem.new()
	item.item_id = item_id
	item.item_text = text
	item.icon = icon
	item.tooltip_id = tooltip_id
	item.selection_changed.connect(_on_selection_item_changed)
	add_child(item)
	return item

func get_selected_item() -> SelectionItem:
	if selected_items.is_empty():
		return null
	return selected_items[0]

func get_selected_items() -> Array[SelectionItem]:
	return selected_items

func get_selected_item_id() -> String:
	var item = get_selected_item()
	return item.item_id if item != null else ""

func clear_selection() -> void:
	for item in selected_items:
		item.set_selected(false)
	selected_items.clear()

# ============================================
# Tooltip Management
# ============================================

func register_tooltip(tooltip_id: String, title: String, body: String, links: Array[Dictionary] = []) -> void:
	tooltip_registry.register_tooltip(tooltip_id, title, body, links)

func _on_item_hover_start(item: ToolbarItem) -> void:
	hovered_item = item
	hover_timer.start()

func _on_item_hover_end(item: ToolbarItem) -> void:
	if hovered_item == item:
		hovered_item = null
		hover_timer.stop()
		
		# Hide tooltip if not locked
		if current_tooltip != null and not current_tooltip.is_locked:
			_hide_current_tooltip()

func _on_hover_timer_timeout() -> void:
	if hovered_item != null and not hovered_item.tooltip_id.is_empty():
		_show_tooltip_for_item(hovered_item)

func _show_tooltip_for_item(item: ToolbarItem) -> void:
	# Don't show new tooltip if we already have a locked one on top
	tooltip_stack = tooltip_stack.filter(func(element): return is_instance_valid(element))
	if not tooltip_stack.is_empty():
		return
	
	var content = tooltip_registry.create_tooltip_content(item.tooltip_id)
	if content == null:
		return
	
	# Close existing unlocked tooltip
	if current_tooltip != null and not current_tooltip.is_locked:
		_hide_current_tooltip()
	
	# Create new tooltip
	current_tooltip = TooltipWindow.new()
	current_tooltip.tooltip_id = item.tooltip_id
	current_tooltip.anchor_item = item
	current_tooltip.preferred_direction = _get_tooltip_direction_vector()
	current_tooltip.window_closed.connect(_on_tooltip_window_closed)
	
	# Connect link signals
	content.link_clicked.connect(_on_tooltip_link_clicked)
	
	
	# Add to scene
	get_tree().root.add_child(current_tooltip)
	current_tooltip.set_content(content)
	current_tooltip.visible = false
	# Position after adding to tree so size is calculated
	await get_tree().process_frame
	current_tooltip.position_relative_to_anchor(get_viewport().get_visible_rect().size)
	current_tooltip.visible = true

func _hide_current_tooltip() -> void:
	if current_tooltip != null:
		current_tooltip.queue_free()
		current_tooltip = null

func _lock_current_tooltip() -> void:
	if current_tooltip == null:
		return
	
	current_tooltip.set_locked(true)
	tooltip_stack.push_back(current_tooltip)
	current_tooltip = null

func _on_tooltip_window_closed() -> void:
	# Remove from stack if it was locked
	cleanup_tooltip_stack()

func cleanup_tooltip_stack():
	for i in range(tooltip_stack.size() - 1, -1, -1):
		if not is_instance_valid(tooltip_stack[i]):
			tooltip_stack.remove_at(i)

func _on_tooltip_link_clicked(tooltip_id: String) -> void:
	# Create a new tooltip window for the linked tooltip
	cleanup_tooltip_stack()
	var content = tooltip_registry.create_tooltip_content(tooltip_id)
	if content == null:
		return
	
	var new_tooltip = TooltipWindow.new()
	get_tree().root.add_child(new_tooltip)
	new_tooltip.tooltip_id = tooltip_id
	new_tooltip.anchor_item = current_tooltip if current_tooltip != null and is_instance_valid(current_tooltip) else tooltip_stack[-1]
	new_tooltip.preferred_direction = _get_tooltip_direction_vector()
	new_tooltip.window_closed.connect(_on_tooltip_window_closed)
	new_tooltip.set_locked(true)  # Nested tooltips start locked
	
	content.link_clicked.connect(_on_tooltip_link_clicked)
	new_tooltip.set_content(content)
	
	
	# Position after adding to tree
	await get_tree().process_frame
	new_tooltip.position_relative_to_anchor(get_viewport().get_visible_rect().size)
	
	tooltip_stack.push_back(new_tooltip)

func _get_tooltip_direction_vector() -> Vector2:
	match tooltip_direction:
		TooltipDirection.UP:
			return Vector2.UP
		TooltipDirection.DOWN:
			return Vector2.DOWN
		TooltipDirection.LEFT:
			return Vector2.LEFT
		TooltipDirection.RIGHT:
			return Vector2.RIGHT
	return Vector2.UP

# ============================================
# Item Callbacks
# ============================================

func _on_action_item_clicked(item: ActionItem) -> void:
	# Action items don't affect selection
	pass

func _on_action_item_triggered(item_id: String) -> void:
	action_triggered.emit(item_id)

func _on_selection_item_clicked(item: SelectionItem) -> void:
	if allow_multiple_selection:
		# Toggle this item
		if item.is_selected:
			item.set_selected(false)
			selected_items.erase(item)
		else:
			item.set_selected(true)
			selected_items.append(item)
	else:
		# Clear other selections
		for selected_item in selected_items:
			if selected_item != item:
				selected_item.set_selected(false)
		selected_items.clear()
		
		# Select this item
		item.set_selected(true)
		selected_items.append(item)
	
	selection_changed.emit(item.item_id)

func _on_selection_item_changed(item_id: String, selected: bool) -> void:
	# This is emitted by the item itself
	pass
