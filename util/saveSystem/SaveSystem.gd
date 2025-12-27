# SaveSystem.gd
class_name SaveSystem
extends RefCounted

const BASE_SAVE_PATH: String = "user://saves/"

# Save a collection of data models
static func save_game(data, save_game_id: String, path: String) -> bool:
	var full_path = BASE_SAVE_PATH + save_game_id + "/" + path
	
	# Ensure directory exists
	var dir = full_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	# Add extension based on format
	if not full_path.ends_with(SaveLoadConfig.JSON_EXT) and not full_path.ends_with(SaveLoadConfig.BINARY_EXT):
		full_path += SaveLoadConfig.get_extension()
	
	# Serialize models
	var serialized = GenericSerializer.to_dict(data)
	
	# Save based on format
	if SaveLoadConfig.USE_JSON_FORMAT:
		return _save_as_json(full_path, serialized)
	else:
		return _save_as_binary(full_path, serialized)

# Save as JSON
static func _save_as_json(file_path: String, data: Variant) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + file_path)
		return false
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true

# Save as binary
static func _save_as_binary(file_path: String, data: Variant) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + file_path)
		return false
	
	# Store magic number to identify binary format
	file.store_32(0x47534156) # "GSAV" in hex
	
	# Store data using var_to_bytes for compact binary representation
	var bytes = var_to_bytes(data)
	file.store_32(bytes.size())
	file.store_buffer(bytes)
	file.close()
	return true

# Recursively serialize values
static func _serialize_value(value):
	return GenericSerializer.to_dict(value)
	#if value == null:
		#return null
	#elif value is bool or value is int or value is float or value is String or value is StringName:
		#return value
	#elif value is Dictionary:
		#var result = {}
		#for key in value:
			#result[key] = _serialize_value(value[key])
		#return result
	#elif value is Array:
		#var result = []
		#for item in value:
			#result.append(_serialize_value(item))
		#return result
	#elif value is Object and value.has_method("to_dict"):
		#if value.has_method("pre_save"):
			#value.pre_save()
		#var result = value.to_dict()
		#if value.has_method("post_save"):
			#value.post_save()
		#return result
	#else:
		#if value is Object and value.has_method("pre_save"):
			#value.pre_save()
		#var result = GenericSerializer.to_dict(value)
		#if value is Object and value.has_method("post_save"):
			#value.post_save()
		#return result
