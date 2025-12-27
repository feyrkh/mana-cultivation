# TypedPropertyAssigner.gd
# Universal property assignment with support for typed arrays and typed dictionaries
class_name TypedPropertyAssigner
extends RefCounted

# Main function: Assign any value to any property with proper type handling
static func assign_property(obj: Object, prop_name: String, value) -> bool:
	if not _property_exists(obj, prop_name):
		push_warning("Property '" + prop_name + "' does not exist on object")
		return false
	
	# Get property info to determine type
	var prop_info = get_property_info(obj, prop_name)
	
	if prop_info.is_empty():
		# Property exists but not in property list (may be dynamic)
		# Try direct assignment
		obj.set(prop_name, value)
		return true
	
	var prop_type = prop_info.get("type", TYPE_NIL)
	
	# Handle based on type
	match prop_type:
		TYPE_ARRAY:
			return _assign_array_property(obj, prop_name, value, prop_info)
		TYPE_DICTIONARY:
			return _assign_dictionary_property(obj, prop_name, value, prop_info)
		_:
			# Regular property, direct assignment works
			obj.set(prop_name, value)
			return true

# Check if a property exists on an object
static func _property_exists(obj: Object, prop_name: String) -> bool:
	return prop_name in obj

# Assign an array property (typed or untyped)
static func _assign_array_property(obj: Object, prop_name: String, value, prop_info: Dictionary) -> bool:
	if value == null:
		obj.set(prop_name, null)
		return true
	
	if not value is Array:
		push_error("Cannot assign non-array value to array property: " + prop_name)
		return false
	
	# Check if it's a typed array
	var hint = prop_info.get("hint", PROPERTY_HINT_NONE)
	var hint_string = prop_info.get("hint_string", "")
	
	if hint == PROPERTY_HINT_ARRAY_TYPE or hint_string != "":
		# Typed array
		obj.set(prop_name, [])
		obj.get(prop_name).assign(value)
		return true
	else:
		# Untyped array, direct assignment
		obj.set(prop_name, value)
		return true

# Assign a dictionary property (typed or untyped)
static func _assign_dictionary_property(obj: Object, prop_name: String, value, prop_info: Dictionary) -> bool:
	if value == null:
		obj.set(prop_name, null)
		return true
	
	if not value is Dictionary:
		push_error("Cannot assign non-dictionary value to dictionary property: " + prop_name)
		return false
	
	obj.set(prop_name, {})
	obj.get(prop_name).assign(value)
	return true

# Parse array element type from hint_string
static func _parse_array_element_type(hint_string: String) -> String:
	if hint_string == "":
		return ""
	
	# Handle different formats
	# Format 1: Just the type name (e.g., "String")
	if not "/" in hint_string and not ":" in hint_string:
		return hint_string
	
	# Format 2: "type_id/hint:className" (e.g., "24/0:StatusEffect")
	if ":" in hint_string:
		var parts = hint_string.split(":")
		if parts.size() >= 2:
			return parts[1]
	
	# Format 3: "type_id/hint" (e.g., "4/0" for int)
	if "/" in hint_string:
		var parts = hint_string.split("/")
		if parts.size() >= 1:
			var type_id = int(parts[0])
			return _type_id_to_name(type_id)
	
	return hint_string

# Parse dictionary key and value types from hint_string
static func _parse_dictionary_types(hint_string: String) -> Dictionary:
	# Dictionary hint format: "KeyType:ValueType"
	# Examples: "String:int", "int:String", "String:StatusEffect"
	
	var result = {
		"key_type": "",
		"value_type": ""
	}
	
	if hint_string == "":
		return result
	
	# Split by colon
	var parts = hint_string.split(":")
	if parts.size() >= 2:
		result["key_type"] = parts[0].strip_edges()
		result["value_type"] = parts[1].strip_edges()
	
	return result

# Convert Variant.Type ID to type name
static func _type_id_to_name(type_id: int) -> String:
	match type_id:
		TYPE_NIL: return ""
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_VECTOR4: return "Vector4"
		TYPE_VECTOR4I: return "Vector4i"
		TYPE_COLOR: return "Color"
		TYPE_RECT2: return "Rect2"
		TYPE_RECT2I: return "Rect2i"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_OBJECT: return "Object"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		_: return ""

# Create a typed array with the given element type
static func _create_typed_array(element_type_name: String, source_array: Array) -> Array:
	if element_type_name == "":
		return source_array
	
	# Create typed array based on element type
	match element_type_name:
		"bool":
			var typed: Array[bool] = []
			typed.assign(source_array)
			return typed
		
		"int":
			var typed: Array[int] = []
			typed.assign(source_array)
			return typed
		
		"float":
			var typed: Array[float] = []
			typed.assign(source_array)
			return typed
		
		"String":
			var typed: Array[String] = []
			typed.assign(source_array)
			return typed
		
		"Vector2":
			var typed: Array[Vector2] = []
			typed.assign(source_array)
			return typed
		
		"Vector2i":
			var typed: Array[Vector2i] = []
			typed.assign(source_array)
			return typed
		
		"Vector3":
			var typed: Array[Vector3] = []
			typed.assign(source_array)
			return typed
		
		"Vector3i":
			var typed: Array[Vector3i] = []
			typed.assign(source_array)
			return typed
		
		"Vector4":
			var typed: Array[Vector4] = []
			typed.assign(source_array)
			return typed
		
		"Vector4i":
			var typed: Array[Vector4i] = []
			typed.assign(source_array)
			return typed
		
		"Color":
			var typed: Array[Color] = []
			typed.assign(source_array)
			return typed
		
		"Dictionary":
			var typed: Array[Dictionary] = []
			typed.assign(source_array)
			return typed
		
		_:
			# Custom class
			return _create_custom_typed_array(element_type_name, source_array)

# Create a typed dictionary with the given key and value types
static func _create_typed_dictionary(types: Dictionary, source_dict: Dictionary) -> Dictionary:
	var key_type = types.get("key_type", "")
	var value_type = types.get("value_type", "")
	
	if key_type == "" or value_type == "":
		return source_dict
	
	# Unfortunately, GDScript doesn't support creating typed dictionaries at runtime
	# The syntax Dictionary[K, V] is only available at compile time
	# We can only validate and return the source dictionary
	
	# For now, we just return the source dictionary
	# Type validation happens at assignment time in Godot
	return source_dict

# Create a typed array for a custom class
static func _create_custom_typed_array(className: String, source_array: Array) -> Array:
	# Try to resolve the class
	var class_ref = _resolve_class(className)
	
	if class_ref == null:
		push_warning("Could not resolve class for typed array: " + className)
		return source_array
	
	# GDScript limitation: Can't create Array[CustomClass] at runtime
	# We use a workaround by creating an array and using assign()
	var typed_array = []
	
	# Try to create a dummy instance to establish type
	var dummy = null
	if class_ref.has_method("new"):
		dummy = class_ref.new()
	
	if dummy != null:
		typed_array = [dummy]
		typed_array.clear()
	
	# Assign will validate types when possible
	typed_array.assign(source_array)
	
	return typed_array

# Resolve a class from a class name
static func _resolve_class(className: String):
	# Try LoadSystem's resolution first
	var resolved = LoadSystem._resolve_class(className)
	if resolved != null:
		return resolved
	
	# Try ClassDB for built-in classes
	if ClassDB.class_exists(className):
		return ClassDB.instantiate(className)
	
	return null

# Get property info for a specific property
static func get_property_info(obj: Object, prop_name: String) -> Dictionary:
	var property_list = obj.get_property_list()
	for prop_info in property_list:
		if prop_info["name"] == prop_name:
			return prop_info
	return {}

# Check if a property is a typed array
static func is_typed_array(obj: Object, prop_name: String) -> bool:
	var prop_info = get_property_info(obj, prop_name)
	if prop_info.is_empty():
		return false
	
	if prop_info.get("type", TYPE_NIL) != TYPE_ARRAY:
		return false
	
	var hint = prop_info.get("hint", PROPERTY_HINT_NONE)
	var hint_string = prop_info.get("hint_string", "")
	
	return hint == PROPERTY_HINT_ARRAY_TYPE or hint_string != ""

# Check if a property is a typed dictionary
static func is_typed_dictionary(obj: Object, prop_name: String) -> bool:
	var prop_info = get_property_info(obj, prop_name)
	if prop_info.is_empty():
		return false
	
	if prop_info.get("type", TYPE_NIL) != TYPE_DICTIONARY:
		return false
	
	var hint = prop_info.get("hint", PROPERTY_HINT_NONE)
	var hint_string = prop_info.get("hint_string", "")
	
	return hint == PROPERTY_HINT_TYPE_STRING and hint_string != ""

# Get the element type name of a typed array property
static func get_array_element_type(obj: Object, prop_name: String) -> String:
	var prop_info = get_property_info(obj, prop_name)
	if prop_info.is_empty():
		return ""
	
	var hint_string = prop_info.get("hint_string", "")
	return _parse_array_element_type(hint_string)

# Get the key and value types of a typed dictionary property
static func get_dictionary_types(obj: Object, prop_name: String) -> Dictionary:
	var prop_info = get_property_info(obj, prop_name)
	if prop_info.is_empty():
		return {"key_type": "", "value_type": ""}
	
	var hint_string = prop_info.get("hint_string", "")
	return _parse_dictionary_types(hint_string)

# Get all property names from an object
static func get_all_property_names(obj: Object, include_internal: bool = false) -> Array[String]:
	var names: Array[String] = []
	var property_list = obj.get_property_list()
	
	for prop_info in property_list:
		var prop_name = prop_info["name"]
		
		# Skip internal properties unless requested
		if not include_internal and prop_name.begins_with("_"):
			continue
		
		# Only include script variables
		var usage = prop_info.get("usage", 0)
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(prop_name)
	
	return names

# Batch assign multiple properties
static func assign_properties(obj: Object, properties: Dictionary) -> Dictionary:
	var results = {}
	
	for prop_name in properties.keys():
		var value = properties[prop_name]
		var success = assign_property(obj, prop_name, value)
		results[prop_name] = success
	
	return results

# Get detailed type information for a property
static func get_property_type_info(obj: Object, prop_name: String) -> Dictionary:
	var prop_info = get_property_info(obj, prop_name)
	
	if prop_info.is_empty():
		return {}
	
	var type_info = {
		"type": prop_info.get("type", TYPE_NIL),
		"type_name": _type_id_to_name(prop_info.get("type", TYPE_NIL)),
		"hint": prop_info.get("hint", PROPERTY_HINT_NONE),
		"hint_string": prop_info.get("hint_string", ""),
		"usage": prop_info.get("usage", 0),
		"is_typed_array": false,
		"is_typed_dictionary": false,
		"array_element_type": "",
		"dict_key_type": "",
		"dict_value_type": ""
	}
	
	# Add array-specific info
	if type_info["type"] == TYPE_ARRAY:
		type_info["is_typed_array"] = is_typed_array(obj, prop_name)
		if type_info["is_typed_array"]:
			type_info["array_element_type"] = get_array_element_type(obj, prop_name)
	
	# Add dictionary-specific info
	if type_info["type"] == TYPE_DICTIONARY:
		type_info["is_typed_dictionary"] = is_typed_dictionary(obj, prop_name)
		if type_info["is_typed_dictionary"]:
			var dict_types = get_dictionary_types(obj, prop_name)
			type_info["dict_key_type"] = dict_types["key_type"]
			type_info["dict_value_type"] = dict_types["value_type"]
	
	return type_info
