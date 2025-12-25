# AutoFormBuilder.gd
class_name AutoFormBuilder
extends VBoxContainer

signal edit_confirmed(models: Dictionary)
signal edit_cancelled()

# Configuration
var edit_mode: bool = false
var models: Dictionary = {}
var original_values: Dictionary = {}
var schemas: Dictionary = {}

# UI References
var form_container: VBoxContainer
var button_container: HBoxContainer
var edit_button: Button
var confirm_button: Button
var cancel_button: Button

# Field node registry for reading values back
var field_nodes: Dictionary = {}

func _init():
	_setup_ui()

func _setup_ui():
	# Main container
	form_container = VBoxContainer.new()
	form_container.name = "FormContainer"
	add_child(form_container)
	
	# Button container
	button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	add_child(button_container)
	
	edit_button = Button.new()
	edit_button.text = "Edit"
	edit_button.pressed.connect(_on_edit_pressed)
	button_container.add_child(edit_button)
	
	confirm_button = Button.new()
	confirm_button.text = "Confirm"
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirm_button.visible = false
	button_container.add_child(confirm_button)
	
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_on_cancel_pressed)
	cancel_button.visible = false
	button_container.add_child(cancel_button)

# Main entry point - show models with optional schemas
func show_models(p_models: Dictionary, p_schemas: Dictionary = {}) -> void:
	models = p_models
	schemas = p_schemas
	edit_mode = false
	_rebuild_form()

# Convenience method for single model
func show_model(model_key: String, model, schema: Dictionary = {}) -> void:
	var models_dict = {model_key: model}
	var schemas_dict = {model_key: schema} if not schema.is_empty() else {}
	show_models(models_dict, schemas_dict)

# Rebuild the entire form
func _rebuild_form() -> void:
	# Clear existing form
	for child in form_container.get_children():
		child.queue_free()
	field_nodes.clear()
	
	# Build form for each model
	for model_key in models.keys():
		var model = models[model_key]
		var schema = schemas.get(model_key, {})
		_build_model_section(model_key, model, schema)
	
	# Update button visibility
	_update_button_visibility()

# Build a section for one model
func _build_model_section(model_key: String, model, schema: Dictionary) -> void:
	# Add section header if multiple models
	if models.size() > 1:
		var header = Label.new()
		header.text = model_key.capitalize()
		header.add_theme_font_size_override("font_size", 18)
		form_container.add_child(header)
		
		var separator = HSeparator.new()
		form_container.add_child(separator)
	
	# Get all properties to display
	var properties = _get_properties(model, schema)
	
	# Build field for each property
	for prop_name in properties:
		var field_path = model_key + "." + prop_name
		var value = _get_property_value(model, prop_name)
		var field_schema = schema.get(prop_name, {})
		
		_build_field(field_path, prop_name, value, field_schema)

# Get list of properties from model
func _get_properties(model, schema: Dictionary) -> Array:
	var properties = []
	
	# If schema specifies fields explicitly, use those
	if schema.has("fields"):
		return schema["fields"]
	
	# Otherwise, introspect the model
	if model is Dictionary:
		properties = model.keys()
	elif model is Object:
		var prop_list = model.get_property_list()
		for prop in prop_list:
			var prop_name = prop["name"]
			# Skip internal properties
			if prop_name.begins_with("_") or prop_name in ["script", "Script Variables"]:
				continue
			# Skip if usage indicates it's not a regular property
			if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				properties.append(prop_name)
	
	return properties

# Get a property value from model
func _get_property_value(model, prop_name: String):
	if model is Dictionary:
		return model.get(prop_name)
	elif model is Object:
		return model.get(prop_name)
	return null

# Set a property value on model
func _set_property_value(model, prop_name: String, value) -> void:
	if model is Dictionary:
		model[prop_name] = value
	elif model is Object:
		model.set(prop_name, value)

# Build a single field
func _build_field(field_path: String, prop_name: String, value, field_schema: Dictionary) -> void:
	# Check if field is readonly
	var is_readonly = field_schema.get("readonly", false)
	var label_text = field_schema.get("label", prop_name.capitalize())
	
	# Create row container
	var row = HBoxContainer.new()
	form_container.add_child(row)
	
	# Label
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 120
	row.add_child(label)
	
	# View node
	var view_node = _create_view_node(value, field_schema)
	view_node.name = field_path + "_view"
	row.add_child(view_node)
	
	# Edit node (if not readonly)
	var edit_node = null
	if not is_readonly:
		edit_node = _create_edit_node(value, field_schema)
		edit_node.name = field_path + "_edit"
		edit_node.visible = false
		row.add_child(edit_node)
	
	# Store references
	field_nodes[field_path] = {
		"view": view_node,
		"edit": edit_node,
		"readonly": is_readonly
	}
	
	# Set initial visibility
	_update_field_visibility(field_path)

# Create view node based on value type
func _create_view_node(value, schema: Dictionary) -> Control:
	# Handle arrays specially
	if value is Array and not value.is_empty():
		# Check if array contains objects/dictionaries
		var first_item = value[0]
		if first_item is Object or first_item is Dictionary:
			return _create_array_view(value, schema)
	
	var label = Label.new()
	label.text = _format_value_for_display(value, schema)
	return label

# Create view for array of objects
func _create_array_view(array: Array, schema: Dictionary) -> Control:
	var array_layout = schema.get("array_layout", "vbox")
	var container: BoxContainer
	
	if array_layout == "hbox":
		container = HBoxContainer.new()
	else:
		container = VBoxContainer.new()
	
	# Add label for the array
	var array_label = Label.new()
	array_label.text = "(%d items)" % array.size()
	array_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(array_label)
	
	# Create sub-form for each item
	var item_schema = schema.get("item_schema", {})
	for i in array.size():
		var item = array[i]
		var item_form = AutoFormBuilder.new()
		item_form.custom_minimum_size = Vector2(0, 0)
		
		# Add a border/background to distinguish sub-forms
		var panel = PanelContainer.new()
		panel.add_child(item_form)
		container.add_child(panel)
		
		# Show the item with a unique key
		var item_key = "item_%d" % i
		item_form.show_model(item_key, item, item_schema)
		
		# Hide the buttons on sub-forms by default
		if item_form.button_container:
			item_form.button_container.visible = schema.get("show_item_buttons", false)
	
	return container

# Create edit node based on value type and schema
func _create_edit_node(value, schema: Dictionary) -> Control:
	# Handle arrays specially
	if value is Array and not value.is_empty():
		var first_item = value[0]
		if first_item is Object or first_item is Dictionary:
			return _create_array_edit(value, schema)
	
	var control_type = schema.get("type", "auto")
	
	# Auto-detect type if not specified
	if control_type == "auto":
		control_type = _detect_control_type(value, schema)
	
	match control_type:
		"string", "text":
			var line_edit = LineEdit.new()
			line_edit.text = str(value) if value != null else ""
			line_edit.custom_minimum_size.x = 200
			return line_edit
		
		"multiline":
			var text_edit = TextEdit.new()
			text_edit.text = str(value) if value != null else ""
			text_edit.custom_minimum_size = Vector2(200, 60)
			return text_edit
		
		"int":
			var spin_box = SpinBox.new()
			spin_box.min_value = schema.get("min", -999999)
			spin_box.max_value = schema.get("max", 999999)
			spin_box.step = schema.get("step", 1)
			spin_box.value = int(value) if value != null else 0
			return spin_box
		
		"float":
			var spin_box = SpinBox.new()
			spin_box.min_value = schema.get("min", -999999.0)
			spin_box.max_value = schema.get("max", 999999.0)
			spin_box.step = schema.get("step", 0.1)
			spin_box.value = float(value) if value != null else 0.0
			spin_box.allow_greater = true
			spin_box.allow_lesser = true
			return spin_box
		
		"bool":
			var check_box = CheckBox.new()
			check_box.button_pressed = bool(value) if value != null else false
			return check_box
		
		"slider":
			var slider = HSlider.new()
			slider.min_value = schema.get("min", 0)
			slider.max_value = schema.get("max", 100)
			slider.step = schema.get("step", 1)
			slider.value = float(value) if value != null else 0
			slider.custom_minimum_size.x = 200
			return slider
		
		_:
			# Default to line edit
			var line_edit = LineEdit.new()
			line_edit.text = str(value) if value != null else ""
			line_edit.custom_minimum_size.x = 200
			return line_edit

# Create edit view for array of objects
func _create_array_edit(array: Array, schema: Dictionary) -> Control:
	var array_layout = schema.get("array_layout", "vbox")
	var container: BoxContainer
	
	if array_layout == "hbox":
		container = HBoxContainer.new()
	else:
		container = VBoxContainer.new()
	
	# Add label for the array
	var array_label = Label.new()
	array_label.text = "(%d items)" % array.size()
	array_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(array_label)
	
	# Create sub-form for each item
	var item_schema = schema.get("item_schema", {})
	for i in array.size():
		var item = array[i]
		var item_form = AutoFormBuilder.new()
		item_form.custom_minimum_size = Vector2(0, 0)
		
		# Add a border/background to distinguish sub-forms
		var panel = PanelContainer.new()
		panel.add_child(item_form)
		container.add_child(panel)
		
		# Show the item in edit mode
		var item_key = "item_%d" % i
		item_form.show_model(item_key, item, item_schema)
		item_form._on_edit_pressed()  # Automatically enter edit mode
		
		# Hide the buttons on sub-forms
		if item_form.button_container:
			item_form.button_container.visible = schema.get("show_item_buttons", false)
		
		# Store reference for reading back values
		if not field_nodes.has("_array_forms"):
			field_nodes["_array_forms"] = []
		field_nodes["_array_forms"].append(item_form)
	
	return container

# Auto-detect appropriate control type
func _detect_control_type(value, schema: Dictionary) -> String:
	if value is bool:
		return "bool"
	elif value is int:
		if schema.has("min") and schema.has("max"):
			var range_size = schema["max"] - schema["min"]
			if range_size <= 100:
				return "slider"
		return "int"
	elif value is float:
		return "float"
	elif value is String:
		if schema.get("multiline", false):
			return "multiline"
		return "string"
	elif value is Array:
		return "readonly"  # Arrays shown as readonly by default
	elif value is Object:
		return "readonly"  # Objects shown as readonly by default
	else:
		return "string"

# Format value for display
func _format_value_for_display(value, schema: Dictionary) -> String:
	if value == null:
		return "(empty)"
	elif value is Array:
		if value.is_empty():
			return "[]"
		var preview = "["
		for i in min(3, value.size()):
			preview += str(value[i])
			if i < value.size() - 1:
				preview += ", "
		if value.size() > 3:
			preview += "..."
		preview += "]"
		return preview
	elif value is Dictionary:
		return str(value)
	elif value is Object:
		if value.has_method("to_string"):
			return value.to_string()
		return str(value.get_class())
	else:
		return str(value)

# Update field visibility based on mode
func _update_field_visibility(field_path: String) -> void:
	if not field_nodes.has(field_path):
		return
	if field_path == '_array_forms':
		return
		
	var nodes = field_nodes[field_path]
	var view_node = nodes["view"]
	var edit_node = nodes["edit"]
	var is_readonly = nodes["readonly"]
	
	if edit_mode and not is_readonly and edit_node != null:
		view_node.visible = false
		edit_node.visible = true
	else:
		view_node.visible = true
		if edit_node != null:
			edit_node.visible = false

# Update all field visibilities
func _update_all_field_visibility() -> void:
	for field_path in field_nodes.keys():
		_update_field_visibility(field_path)

# Update button visibility based on mode
func _update_button_visibility() -> void:
	edit_button.visible = not edit_mode
	confirm_button.visible = edit_mode
	cancel_button.visible = edit_mode

# Switch to edit mode
func _on_edit_pressed() -> void:
	edit_mode = true
	original_values = _deep_copy_models(models)
	_update_all_field_visibility()
	_update_button_visibility()

# Confirm changes
func _on_confirm_pressed() -> void:
	if not edit_mode:
		return
	
	# Read all edited values back into models
	for field_path in field_nodes.keys():
		if field_path == "_array_forms":
			continue  # Skip the array forms storage
			
		var nodes = field_nodes[field_path]
		if nodes["readonly"] or nodes["edit"] == null:
			continue
		
		var edit_node = nodes["edit"]
		var new_value = _get_node_value(edit_node)
		
		# Parse field path
		var parts = field_path.split(".")
		if parts.size() < 2:
			continue
		
		var model_key = parts[0]
		var prop_name = parts[1]
		
		if models.has(model_key):
			var current_value = _get_property_value(models[model_key], prop_name)
			
			# Handle arrays of objects specially
			if current_value is Array and not current_value.is_empty():
				var first_item = current_value[0]
				if first_item is Object or first_item is Dictionary:
					# Update array items from sub-forms
					if field_nodes.has("_array_forms"):
						var sub_forms = field_nodes["_array_forms"]
						for i in sub_forms.size():
							if i < current_value.size():
								var sub_form = sub_forms[i]
								# Trigger confirm on sub-form to update its model
								sub_form._on_confirm_pressed()
								# The array item has been updated by reference
					continue
			
			_set_property_value(models[model_key], prop_name, new_value)
			
			# Update view node
			var view_node = nodes["view"]
			if view_node is Label:
				var schema = _get_field_schema(model_key, prop_name)
				view_node.text = _format_value_for_display(new_value, schema)
	
	edit_mode = false
	original_values.clear()
	field_nodes.erase("_array_forms")  # Clear array form references
	_update_all_field_visibility()
	_update_button_visibility()
	
	edit_confirmed.emit(models)

# Cancel changes
func _on_cancel_pressed() -> void:
	if not edit_mode:
		return
	
	# Restore original values
	models = _deep_copy_models(original_values)
	original_values.clear()
	
	# Rebuild form to show original values
	edit_mode = false
	_rebuild_form()
	
	edit_cancelled.emit()

# Get schema for a specific field
func _get_field_schema(model_key: String, prop_name: String) -> Dictionary:
	if schemas.has(model_key):
		var model_schema = schemas[model_key]
		if model_schema.has(prop_name):
			return model_schema[prop_name]
	return {}

# Get value from a control node
func _get_node_value(node: Control):
	if node is LineEdit:
		return node.text
	elif node is TextEdit:
		return node.text
	elif node is SpinBox:
		return node.value
	elif node is CheckBox or node is CheckButton:
		return node.button_pressed
	elif node is Slider or node is HSlider or node is VSlider:
		return node.value
	else:
		return null

# Deep copy models
func _deep_copy_models(source: Dictionary) -> Dictionary:
	var result = {}
	for key in source.keys():
		result[key] = _deep_copy_value(source[key])
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
		var dict = value.to_dict()
		if value.has_method("from_dict"):
			return value.get_script().from_dict(dict)
		return dict
	else:
		return value
