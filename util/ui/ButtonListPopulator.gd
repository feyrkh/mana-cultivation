# ButtonListPopulator.gd
class_name ButtonListPopulator
extends RefCounted

signal button_clicked(object: Variant, index: int)
signal button_hovered(object: Variant, index: int)
signal button_unhovered(object: Variant, index: int)

var container: Container
var objects: Array
var format_string: String
var button_nodes: Array[Button] = []

func _init(p_container: Container, p_objects: Array = [], p_format_string: String = "") -> void:
	container = p_container
	objects = p_objects
	format_string = p_format_string

# Populate the container with buttons based on current objects and format
func populate() -> void:
	clear()
	
	for i in range(objects.size()):
		var obj = objects[i]
		var button = Button.new()
		button.text = _format_object(obj)
		button.pressed.connect(_on_button_pressed.bind(obj, i))
		button.mouse_entered.connect(_on_button_hovered.bind(obj, i))
		button.mouse_exited.connect(_on_button_unhovered.bind(obj, i))
		
		container.add_child(button)
		button_nodes.append(button)

# Clear all buttons from container
func clear() -> void:
	for button in button_nodes:
		if is_instance_valid(button):
			button.queue_free()
	button_nodes.clear()

# Update the objects list and repopulate
func set_objects(p_objects: Array) -> void:
	objects = p_objects
	populate()

# Update the format string and repopulate
func set_format_string(p_format_string: String) -> void:
	format_string = p_format_string
	populate()

# Update both objects and format string, then repopulate
func update(p_objects: Array, p_format_string: String) -> void:
	objects = p_objects
	format_string = p_format_string
	populate()

# Refresh the display without changing data
func refresh() -> void:
	populate()

# Format an object using the format string
func _format_object(obj: Variant) -> String:
	var result = format_string
	
	# Find all {field.path} patterns
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	
	var matches = regex.search_all(result)
	for match in matches:
		var field_path = match.get_string(1)
		var value = _get_nested_value(obj, field_path)
		result = result.replace("{" + field_path + "}", str(value))
	
	return result

# Get a value from a nested path like "cost.amt" or "stats.hp"
func _get_nested_value(obj: Variant, path: String) -> Variant:
	var parts = path.split(".")
	var current = obj
	
	for part in parts:
		if current == null:
			push_warning("Null value encountered in path: " + path)
			return ""
		
		if current is Dictionary:
			if current.has(part):
				current = current[part]
			else:
				push_warning("Dictionary key not found: " + part + " in path: " + path)
				return ""
		elif current is Object:
			if part in current:
				current = current.get(part)
			else:
				push_warning("Object property not found: " + part + " in path: " + path)
				return ""
		else:
			push_warning("Cannot navigate path: " + path + " at part: " + part)
			return ""
	
	return current

# Handle button press
func _on_button_pressed(obj: Variant, index: int) -> void:
	button_clicked.emit(obj, index)

# Handle button hover
func _on_button_hovered(obj: Variant, index: int) -> void:
	button_hovered.emit(obj, index)

# Handle button unhover
func _on_button_unhovered(obj: Variant, index: int) -> void:
	button_unhovered.emit(obj, index)

# Get a specific button by index
func get_button(index: int) -> Button:
	if index >= 0 and index < button_nodes.size():
		return button_nodes[index]
	return null

# Get all buttons
func get_buttons() -> Array[Button]:
	return button_nodes

# Enable/disable a specific button
func set_button_enabled(index: int, enabled: bool) -> void:
	var button = get_button(index)
	if button != null:
		button.disabled = not enabled

# Enable/disable all buttons
func set_all_buttons_enabled(enabled: bool) -> void:
	for button in button_nodes:
		button.disabled = not enabled
