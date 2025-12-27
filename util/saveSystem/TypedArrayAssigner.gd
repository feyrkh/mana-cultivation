# TypedArrayAssigner.gd
# Utility for assigning typed arrays using property introspection
class_name TypedArrayAssigner
extends RefCounted

# Assign a value to a property, handling typed arrays correctly
static func assign_property(obj: Object, prop_name: String, value) -> bool:
	# Get property info to check if it's a typed array
	var property_list = obj.get_property_list()
	
	for prop_info in property_list:
		if prop_info["name"] == prop_name:
			return _assign_with_type_info(obj, prop_name, value, prop_info)
	
	# Property not found in property list, try direct assignment
	push_warning("Property '" + prop_name + "' not found in property list, attempting direct assignment")
	obj.set(prop_name, value)
	return true

# Assign with type information from property info
static func _assign_with_type_info(obj: Object, prop_name: String, value, prop_info: Dictionary) -> bool:
	var prop_type = prop_info.get("type", TYPE_NIL)
	
	# Check if it's an array
	if prop_type == TYPE_ARRAY:
		# Check if it's a typed array
		var className = prop_info.get("class_name", "")
		var hint = prop_info.get("hint", PROPERTY_HINT_NONE)
		var hint_string = prop_info.get("hint_string", "")
		
		# Typed arrays have specific hint information
		if hint == PROPERTY_HINT_ARRAY_TYPE or hint_string != "":
			return _assign_typed_array(obj, prop_name, value, hint_string, prop_info)
		else:
			# Regular untyped array, direct assignment works
			obj.set(prop_name, value)
			return true
	else:
		# Not an array, direct assignment
		obj.set(prop_name, value)
		return true

# Assign a typed array by creating a properly typed array
static func _assign_typed_array(obj: Object, prop_name: String, value, hint_string: String, prop_info: Dictionary) -> bool:
	if not value is Array:
		push_error("Cannot assign non-array value to typed array property: " + prop_name)
		return false
	
	# Parse the type from hint_string
	# Format examples:
	# "String" -> Array[String]
	# "31/0:Resource" -> Array[Resource]
	# "24/0:StatusEffect" -> Array[StatusEffect]
	
	var element_type_name = _parse_array_element_type(hint_string)
	
	# Create a new typed array with the correct type
	var typed_array = _create_typed_array(element_type_name, value)
	
	if typed_array != null:
		obj.set(prop_name, typed_array)
		return true
	else:
		push_warning("Could not create typed array for property: " + prop_name)
		# Fallback: try direct assignment anyway
		obj.set(prop_name, value)
		return false

# Parse the element type from hint_string
static func _parse_array_element_type(hint_string: String) -> String:
	if hint_string == "":
		return ""
	
	# Handle different formats
	# Format 1: Just the type name (e.g., "String")
	if not "/" in hint_string and not ":" in hint_string:
		return hint_string
	
	# Format 2: "type_id/hint:class_name" (e.g., "24/0:StatusEffect")
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
		# No type specified, return as-is
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
			# Custom class - try to resolve it
			return _create_custom_typed_array(element_type_name, source_array)

# Create a typed array for a custom class
static func _create_custom_typed_array(className: String, source_array: Array) -> Array:
	# Try to resolve the class
	var class_ref = _resolve_class(className)
	
	if class_ref == null:
		push_warning("Could not resolve class for typed array: " + className)
		return source_array  # Return untyped as fallback
	
	# Create a typed array using the script as the type
	# Note: We can't directly create Array[CustomClass] at runtime in GDScript
	# But we can create an array and use assign() which validates types
	
	# Create a dummy typed array by instantiating one element
	var dummy = class_ref.new() if class_ref.has_method("new") else null
	
	if dummy == null:
		push_warning("Could not instantiate class for typed array: " + className)
		return source_array
	
	# Unfortunately, GDScript doesn't allow us to create Array[T] dynamically
	# We need to use a workaround: create an array with the dummy element, then clear and assign
	var typed_array = [dummy]
	typed_array.clear()
	
	# Set the typed array's script/type by assigning
	# This is a limitation of GDScript - we can't create truly typed arrays at runtime
	# But assign() will validate types when possible
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

# Helper: Get detailed property info
static func get_property_info(obj: Object, prop_name: String) -> Dictionary:
	var property_list = obj.get_property_list()
	for prop_info in property_list:
		if prop_info["name"] == prop_name:
			return prop_info
	return {}

# Helper: Check if a property is a typed array
static func is_typed_array(obj: Object, prop_name: String) -> bool:
	var prop_info = get_property_info(obj, prop_name)
	if prop_info.is_empty():
		return false
	
	if prop_info.get("type", TYPE_NIL) != TYPE_ARRAY:
		return false
	
	var hint = prop_info.get("hint", PROPERTY_HINT_NONE)
	var hint_string = prop_info.get("hint_string", "")
	
	return hint == PROPERTY_HINT_ARRAY_TYPE or hint_string != ""

# Helper: Get the element type name of a typed array property
static func get_array_element_type(obj: Object, prop_name: String) -> String:
	var prop_info = get_property_info(obj, prop_name)
	if prop_info.is_empty():
		return ""
	
	var hint_string = prop_info.get("hint_string", "")
	return _parse_array_element_type(hint_string)
