class_name LoadSystem
extends RefCounted

const BASE_SAVE_PATH: String = "user://saves/"

# Class registry for deserialization (optional fallback)
static var class_registry: Dictionary = {}

# Register a custom class for deserialization (optional)
static func register_class(className: String, class_ref) -> void:
	class_registry[className] = class_ref

# Load game data from save
static func load_object(save_game_id: String, path: String) -> Variant:
	var base_path = BASE_SAVE_PATH + save_game_id + "/" + path
	
	# Try both extensions to autodetect format
	var file_path: String = ""
	var is_json: bool = false
	
	if FileAccess.file_exists(base_path):
		file_path = base_path
		is_json = _is_json_file(file_path)
	elif FileAccess.file_exists(base_path + SaveLoadConfig.JSON_EXT):
		file_path = base_path + SaveLoadConfig.JSON_EXT
		is_json = true
	elif FileAccess.file_exists(base_path + SaveLoadConfig.BINARY_EXT):
		file_path = base_path + SaveLoadConfig.BINARY_EXT
		is_json = false
	else:
		push_error("Save file not found: " + base_path)
		return []
	
	# Load based on detected format
	var data
	if is_json:
		data = _load_from_json(file_path)
	else:
		data = _load_from_binary(file_path)
	return GenericSerializer.from_dict(data)
	#if data_array.is_empty():
		#return []
	#
	# Deserialize models
	#var models: Array = []
	#for data in data_array:
		#if data is Dictionary and data.has("__class__"):
			#var model = _deserialize_object(data)
			#if model != null:
				#models.append(model)
		#else:
			#models.append(data)
	#
	#return models

# Detect if file is JSON by checking first character
static func _is_json_file(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	
	var first_byte = file.get_8()
	file.close()
	
	# JSON files start with '[' (91) or whitespace
	# Binary files start with magic number 0x47 ('G')
	return first_byte == 91 or first_byte == 32 or first_byte == 9 or first_byte == 10

# Load from JSON
static func _load_from_json(file_path: String) -> Variant:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + file_path)
		return []
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return []
	
	var data = json.get_data()
	return data

# Load from binary
static func _load_from_binary(file_path: String) -> Array:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + file_path)
		return []
	
	# Verify magic number
	var magic = file.get_32()
	if magic != 0x47534156:
		push_error("Invalid binary save file format")
		file.close()
		return []
	
	# Read data
	var data_size = file.get_32()
	var bytes = file.get_buffer(data_size)
	file.close()
	
	var data = bytes_to_var(bytes)
	return data

# Resolve a class reference from a class name string
static func _resolve_class(className: String):
	# First, check the manual registry (for backwards compatibility)
	if class_registry.has(className):
		return class_registry[className]
	
	# Try to get the class from the global scope using ClassDB
	# Note: This works for classes registered with class_name
	if ClassDB.class_exists(className):
		# ClassDB contains built-in classes, but custom classes need different approach
		# For built-in classes:
		var instance = ClassDB.instantiate(className)
		if instance != null:
			var class_ref = instance.get_script()
			instance.free() if instance is Object else null
			class_registry[className] = class_ref
			print("LoadSystem: Registering builtin class '%s'" % class_ref)
			return class_ref
	
	# Try using the global script class registry
	# In Godot 4, classes with class_name are available globally
	var global_class = _get_global_class(className)
	if global_class != null:
		class_registry[className] = global_class
		print("LoadSystem: Registering global class '%s'" % className)
		return global_class
	
	push_error("LoadSystem: Failed to find class with name '%s'" % className)
	return null

# Get a global script class by name
static func _get_global_class(className: String):
	# In Godot 4, we can access script classes through ProjectSettings
	# Get the list of global script classes
	var global_classes = ProjectSettings.get_global_class_list()
	
	for class_info in global_classes:
		if class_info.get("class", "") == className:
			var script_path = class_info.get("path", "")
			if script_path != "":
				return load(script_path)
	
	return null
