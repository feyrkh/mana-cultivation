# ModelRenderer.gd
class_name ModelRenderer
extends Control

signal edit_confirmed(models: Dictionary)
signal edit_cancelled()

# Configuration
var edit_mode: bool = false
var models: Dictionary = {}
var original_values: Dictionary = {}
var uneditable_fields: Array[String] = []

# UI container reference
@onready var container: Control = self

# Override this in subclasses to provide custom field mappings
# Format: {"model_key.field.path": "NodeName"}
func get_render_mapping() -> Dictionary:
	return {}

# Show the models with the renderer
func show_models(p_models: Dictionary, p_edit_mode: bool = false) -> void:
	models = p_models
	edit_mode = p_edit_mode
	
	# Store original values for cancel functionality
	if edit_mode:
		original_values = _deep_copy_models(models)
	
	_render()

# Render all fields based on mapping
func _render() -> void:
	var mapping = get_render_mapping()
	
	for field_path in mapping.keys():
		var node_name = mapping[field_path]
		_render_field(field_path, node_name)

# Render a single field
func _render_field(field_path: String, node_name: String) -> void:
	var value = _get_value_from_path(field_path)
	var is_uneditable = field_path in uneditable_fields
	
	if edit_mode and not is_uneditable:
		# Try to find edit version first
		var edit_node = _find_node_by_name(node_name + "Edit")
		var view_node = _find_node_by_name(node_name + "View")
		
		if edit_node != null:
			# Edit node exists, use it and hide view
			_set_node_value(edit_node, value)
			edit_node.visible = true
			if view_node != null:
				view_node.visible = false
		elif view_node != null:
			# No edit node, just use view node
			_set_node_value(view_node, value)
			view_node.visible = true
		else:
			# Try base name without suffix
			var base_node = _find_node_by_name(node_name)
			if base_node != null:
				_set_node_value(base_node, value)
				base_node.visible = true
	else:
		# View mode or uneditable field
		var view_node = _find_node_by_name(node_name + "View")
		var edit_node = _find_node_by_name(node_name + "Edit")
		
		if view_node != null:
			_set_node_value(view_node, value)
			view_node.visible = true
			if edit_node != null:
				edit_node.visible = false
		else:
			# Try base name without suffix
			var base_node = _find_node_by_name(node_name)
			if base_node != null:
				_set_node_value(base_node, value)
				base_node.visible = true
				
# Get value from a dot-notation path like "char1.stats.hp"
func _get_value_from_path(path: String):
	var parts = path.split(".")
	if parts.is_empty():
		return null
	
	# First part is the model key
	var model_key = parts[0]
	if not models.has(model_key):
		push_warning("Model key not found: " + model_key)
		return null
	
	var current = models[model_key]
	
	# Navigate through remaining parts
	for i in range(1, parts.size()):
		var part = parts[i]
		
		if current is Dictionary:
			if current.has(part):
				current = current[part]
			else:
				push_warning("Dictionary key not found: " + part + " in path: " + path)
				return null
		elif current is Object:
			if part in current:
				current = current.get(part)
			else:
				push_warning("Object property not found: " + part + " in path: " + path)
				return null
		else:
			push_warning("Cannot navigate path: " + path + " at part: " + part)
			return null
	
	return current

# Set value back to a path (for saving edits)
func _set_value_to_path(path: String, value) -> bool:
	var parts = path.split(".")
	if parts.size() < 2:
		return false
	
	var model_key = parts[0]
	if not models.has(model_key):
		return false
	
	var current = models[model_key]
	
	# Navigate to parent of final property
	for i in range(1, parts.size() - 1):
		var part = parts[i]
		
		if current is Dictionary:
			if current.has(part):
				current = current[part]
			else:
				return false
		elif current is Object:
			if part in current:
				current = current.get(part)
			else:
				return false
		else:
			return false
	
	# Set the final property
	var final_key = parts[-1]
	if current is Dictionary:
		current[final_key] = value
		return true
	elif current is Object:
		current.set(final_key, value)
		return true
	
	return false

# Find a node by name in the container
func _find_node_by_name(node_name: String) -> Node:
	return _recursive_find_node(container, node_name)

func _recursive_find_node(parent: Node, node_name: String) -> Node:
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = _recursive_find_node(child, node_name)
		if result != null:
			return result
	
	return null

# Set value to a node based on its type
func _set_node_value(node: Node, value) -> void:
	if node is Label:
		node.text = str(value)
	elif node is ModelRenderer:
		node.show_models({'value': value}, edit_mode)
	elif node is LineEdit:
		node.text = str(value)
	elif node is TextEdit:
		node.text = str(value)
	elif node is SpinBox:
		if value is int or value is float:
			node.value = value
		else:
			node.value = float(str(value))
	elif node is CheckBox or node is CheckButton:
		node.button_pressed = bool(value)
	elif node is OptionButton:
		# For OptionButton, value should be the selected index
		if value is int:
			node.selected = value
	elif node is Slider or node is HSlider or node is VSlider:
		if value is int or value is float:
			node.value = value
		else:
			node.value = float(str(value))
	elif node.has_method("set_value"):
		# Custom control with set_value method
		node.set_value(value)
	else:
		push_warning("Unsupported node type for value setting: " + node.get_class())

# Get value from a node based on its type
func _get_node_value(node: Node):
	if node is LineEdit:
		return node.text
	elif node is TextEdit:
		return node.text
	elif node is SpinBox:
		return node.value
	elif node is CheckBox or node is CheckButton:
		return node.button_pressed
	elif node is OptionButton:
		return node.selected
	elif node is Slider or node is HSlider or node is VSlider:
		return node.value
	elif node.has_method("get_value"):
		# Custom control with get_value method
		return node.get_value()
	elif node is Label:
		return node.text
	else:
		push_warning("Unsupported node type for value getting: " + node.get_class())
		return null

# Confirm edits and apply changes
func confirm_edit() -> void:
	if not edit_mode:
		return
	
	var mapping = get_render_mapping()
	
	# Gather all edited values
	for field_path in mapping.keys():
		if field_path in uneditable_fields:
			continue
			
		var node_name = mapping[field_path]
		var edit_node = _find_node_by_name(node_name + "Edit")
		
		if edit_node == null:
			edit_node = _find_node_by_name(node_name)
		
		if edit_node != null:
			var new_value = _get_node_value(edit_node)
			_set_value_to_path(field_path, new_value)
	
	edit_mode = false
	original_values.clear()
	
	# Re-render in view mode
	_render()
	
	edit_confirmed.emit(models)

# Cancel edits and revert to original values
func cancel_edit() -> void:
	if not edit_mode:
		return
	
	# Restore original values
	models = _deep_copy_models(original_values)
	original_values.clear()
	edit_mode = false
	
	# Re-render in view mode
	_render()
	
	edit_cancelled.emit()

# Mark fields as uneditable
func set_uneditable_fields(fields: Array[String]) -> void:
	uneditable_fields = fields

# Deep copy models for backup
func _deep_copy_models(source: Dictionary) -> Dictionary:
	var result = {}
	for key in source.keys():
		var value = source[key]
		result[key] = _deep_copy_value(value)
	return result

func _deep_copy_value(value):
	if value == null:
		return null
	elif value is Dictionary:
		var copy = {}
		for k in value.keys():
			copy[k] = _deep_copy_value(value[k])
		return copy
	elif value is Array:
		var copy = []
		for item in value:
			copy.append(_deep_copy_value(item))
		return copy
	elif value is Object and value.has_method("duplicate"):
		return value.duplicate()
	elif value is Object and value.has_method("to_dict"):
		# For custom classes with serialization
		var dict = value.to_dict()
		if value.has_method("from_dict"):
			return value.get_script().from_dict(dict)
		return dict
	else:
		# Primitives (int, float, String, bool) are passed by value
		return value

# Refresh the display without changing mode
func refresh() -> void:
	_render()
