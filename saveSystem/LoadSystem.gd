# LoadSystem.gd
class_name LoadSystem
extends RefCounted

const BASE_SAVE_PATH: String = "user://saves/"

# Class registry for deserialization
static var class_registry: Dictionary = {
	"StatusEffect": StatusEffect,
	"Character": Character
}

# Register a custom class for deserialization
static func register_class(className: String, class_ref) -> void:
	class_registry[className] = class_ref

# Load game data from save
static func load_game(save_game_id: String, path: String) -> Array:
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
	var data_array: Array = []
	if is_json:
		data_array = _load_from_json(file_path)
	else:
		data_array = _load_from_binary(file_path)
	
	if data_array.is_empty():
		return []
	
	# Deserialize models
	var models: Array = []
	for data in data_array:
		if data is Dictionary and data.has("__class__"):
			var model = _deserialize_object(data)
			if model != null:
				models.append(model)
		else:
			models.append(data)
	
	return models

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
static func _load_from_json(file_path: String) -> Array:
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
	if data is Array:
		return data
	else:
		return [data]

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
	if data is Array:
		return data
	else:
		return [data]

# Deserialize an object from dictionary
static func _deserialize_object(dict: Dictionary):
	var className = dict.get("__class__", "")
	
	if class_registry.has(className):
		var class_ref = class_registry[className]
		if class_ref.has_method("from_dict"):
			return class_ref.from_dict(dict)
	
	push_warning("Unknown class for deserialization: " + className)
	return null
