# GenericSerializer.gd
class_name GenericSerializer
extends RefCounted

# Serialize any object to a dictionary recursively
static func to_dict(value) -> Variant:
	if value == null:
		return null
	
	# Primitives - return as-is
	if value is bool or value is int or value is float or value is String:
		return value
	
	# Object with to_dict method - use it
	if value is Object and value.has_method("to_dict"):
		return value.to_dict()
	
	# Dictionary - recurse on values
	if value is Dictionary:
		var result = {}
		result["__type__"] = "Dictionary"
		result["data"] = {}
		for key in value.keys():
			# Keys are serialized too, in case they're complex
			var serialized_key = _serialize_dict_key(key)
			result["data"][serialized_key] = to_dict(value[key])
		return result
	
	# Array - recurse on elements
	if value is Array:
		var result = {}
		result["__type__"] = "Array"
		result["data"] = []
		for item in value:
			result["data"].append(to_dict(item))
		return result
	
	# Vector types
	if value is Vector2:
		return {"__type__": "Vector2", "x": value.x, "y": value.y}
	if value is Vector2i:
		return {"__type__": "Vector2i", "x": value.x, "y": value.y}
	if value is Vector3:
		return {"__type__": "Vector3", "x": value.x, "y": value.y, "z": value.z}
	if value is Vector3i:
		return {"__type__": "Vector3i", "x": value.x, "y": value.y, "z": value.z}
	if value is Vector4:
		return {"__type__": "Vector4", "x": value.x, "y": value.y, "z": value.z, "w": value.w}
	if value is Vector4i:
		return {"__type__": "Vector4i", "x": value.x, "y": value.y, "z": value.z, "w": value.w}
	
	# Color
	if value is Color:
		return {
			"__type__": "Color",
			"r": value.r,
			"g": value.g,
			"b": value.b,
			"a": value.a
		}
	
	# Rect2
	if value is Rect2:
		return {
			"__type__": "Rect2",
			"position": to_dict(value.position),
			"size": to_dict(value.size)
		}
	if value is Rect2i:
		return {
			"__type__": "Rect2i",
			"position": to_dict(value.position),
			"size": to_dict(value.size)
		}
	
	# Transform types
	if value is Transform2D:
		return {
			"__type__": "Transform2D",
			"x": to_dict(value.x),
			"y": to_dict(value.y),
			"origin": to_dict(value.origin)
		}
	if value is Transform3D:
		return {
			"__type__": "Transform3D",
			"basis": to_dict(value.basis),
			"origin": to_dict(value.origin)
		}
	if value is Basis:
		return {
			"__type__": "Basis",
			"x": to_dict(value.x),
			"y": to_dict(value.y),
			"z": to_dict(value.z)
		}
	
	# Quaternion
	if value is Quaternion:
		return {
			"__type__": "Quaternion",
			"x": value.x,
			"y": value.y,
			"z": value.z,
			"w": value.w
		}
	
	# Plane
	if value is Plane:
		return {
			"__type__": "Plane",
			"normal": to_dict(value.normal),
			"d": value.d
		}
	
	# AABB
	if value is AABB:
		return {
			"__type__": "AABB",
			"position": to_dict(value.position),
			"size": to_dict(value.size)
		}
	
	# Generic Object - introspect properties
	if value is Object:
		return _serialize_generic_object(value)
	
	# Fallback - convert to string
	push_warning("Unsupported type for serialization: " + str(typeof(value)) + ", converting to string")
	return {"__type__": "String", "value": str(value)}

# Serialize dictionary keys (they can be any type)
static func _serialize_dict_key(key) -> String:
	if key is String:
		return key
	elif key is int:
		return "__int__:" + str(key)
	elif key is float:
		return "__float__:" + str(key)
	elif key is Vector2i:
		return "__Vector2i__:" + str(key.x) + "," + str(key.y)
	elif key is Vector2:
		return "__Vector2__:" + str(key.x) + "," + str(key.y)
	else:
		# Fallback: convert to string
		return "__generic__:" + str(key)

# Deserialize dictionary keys
static func _deserialize_dict_key(key_str: String) -> Variant:
	if key_str.begins_with("__int__:"):
		return int(key_str.substr(8))
	elif key_str.begins_with("__float__:"):
		return float(key_str.substr(10))
	elif key_str.begins_with("__Vector2i__:"):
		var parts = key_str.substr(13).split(",")
		return Vector2i(int(parts[0]), int(parts[1]))
	elif key_str.begins_with("__Vector2__:"):
		var parts = key_str.substr(12).split(",")
		return Vector2(float(parts[0]), float(parts[1]))
	elif key_str.begins_with("__generic__:"):
		return key_str.substr(12)
	else:
		return key_str

# Serialize a generic object by introspecting its properties
static func _serialize_generic_object(obj: Object) -> Dictionary:
	var result = {}
	result["__type__"] = "Object"
	
	# Get class name if available
	if obj.has_method("get_class"):
		result["__class__"] = obj.get_class()
	elif obj.get_script() != null:
		result["__script__"] = obj.get_script().resource_path
	
	result["properties"] = {}
	
	# Get all properties
	var property_list = obj.get_property_list()
	for prop_info in property_list:
		var prop_name = prop_info["name"]
		
		# Skip internal properties
		if prop_name.begins_with("_"):
			continue
		
		# Skip certain usage flags (script variables, etc.)
		var usage = prop_info["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var prop_value = obj.get(prop_name)
			result["properties"][prop_name] = to_dict(prop_value)
	
	return result

# Deserialize from dictionary recursively
static func from_dict(dict) -> Variant:
	if dict == null:
		return null
	
	# Not a dictionary - return as-is
	if not dict is Dictionary:
		return dict
	
	# Check for type marker
	if not dict.has("__type__"):
		# No type marker - might be a plain dictionary or a custom class
		if dict.has("__class__"):
			# Custom class with from_dict method
			return _deserialize_custom_class(dict)
		else:
			# Plain dictionary - deserialize recursively without type wrapper
			var result = {}
			for key in dict.keys():
				result[key] = from_dict(dict[key])
			return result
	
	var type_name = dict["__type__"]
	
	# Handle each type
	match type_name:
		"Dictionary":
			var result = {}
			var data = dict.get("data", {})
			for key_str in data.keys():
				var actual_key = _deserialize_dict_key(key_str)
				result[actual_key] = from_dict(data[key_str])
			return result
		
		"Array":
			var result = []
			var data = dict.get("data", [])
			for item in data:
				result.append(from_dict(item))
			return result
		
		"Vector2":
			return Vector2(dict.get("x", 0.0), dict.get("y", 0.0))
		
		"Vector2i":
			return Vector2i(dict.get("x", 0), dict.get("y", 0))
		
		"Vector3":
			return Vector3(dict.get("x", 0.0), dict.get("y", 0.0), dict.get("z", 0.0))
		
		"Vector3i":
			return Vector3i(dict.get("x", 0), dict.get("y", 0), dict.get("z", 0))
		
		"Vector4":
			return Vector4(dict.get("x", 0.0), dict.get("y", 0.0), dict.get("z", 0.0), dict.get("w", 0.0))
		
		"Vector4i":
			return Vector4i(dict.get("x", 0), dict.get("y", 0), dict.get("z", 0), dict.get("w", 0))
		
		"Color":
			return Color(
				dict.get("r", 0.0),
				dict.get("g", 0.0),
				dict.get("b", 0.0),
				dict.get("a", 1.0)
			)
		
		"Rect2":
			return Rect2(
				from_dict(dict.get("position")),
				from_dict(dict.get("size"))
			)
		
		"Rect2i":
			return Rect2i(
				from_dict(dict.get("position")),
				from_dict(dict.get("size"))
			)
		
		"Transform2D":
			var transform = Transform2D()
			transform.x = from_dict(dict.get("x"))
			transform.y = from_dict(dict.get("y"))
			transform.origin = from_dict(dict.get("origin"))
			return transform
		
		"Transform3D":
			return Transform3D(
				from_dict(dict.get("basis")),
				from_dict(dict.get("origin"))
			)
		
		"Basis":
			var basis = Basis()
			basis.x = from_dict(dict.get("x"))
			basis.y = from_dict(dict.get("y"))
			basis.z = from_dict(dict.get("z"))
			return basis
		
		"Quaternion":
			return Quaternion(
				dict.get("x", 0.0),
				dict.get("y", 0.0),
				dict.get("z", 0.0),
				dict.get("w", 1.0)
			)
		
		"Plane":
			return Plane(
				from_dict(dict.get("normal")),
				dict.get("d", 0.0)
			)
		
		"AABB":
			return AABB(
				from_dict(dict.get("position")),
				from_dict(dict.get("size"))
			)
		
		"String":
			return dict.get("value", "")
		
		"Object":
			return _deserialize_generic_object(dict)
		
		_:
			push_warning("Unknown type in deserialization: " + type_name)
			return dict

# Deserialize a custom class (with __class__ marker)
static func _deserialize_custom_class(dict: Dictionary) -> Variant:
	var className = dict.get("__class__", "")
	
	# Check if registered in LoadSystem
	if LoadSystem.class_registry.has(className):
		var class_ref = LoadSystem.class_registry[className]
		if class_ref.has_method("from_dict"):
			return class_ref.from_dict(dict)
	
	# Fallback to generic object deserialization
	push_warning("Custom class not registered or missing from_dict: " + className)
	return _deserialize_generic_object(dict)

# Deserialize a generic object (best effort)
static func _deserialize_generic_object(dict: Dictionary) -> Variant:
	# For generic objects without a specific class, return as dictionary
	# This is a limitation - we can't reconstruct arbitrary objects
	push_warning("Generic object deserialization: returning as dictionary")
	
	var properties = dict.get("properties", {})
	var result = {}
	
	for prop_name in properties.keys():
		result[prop_name] = from_dict(properties[prop_name])
	
	return result

# Helper: Deep copy any value using serialization
static func deep_copy(value) -> Variant:
	return from_dict(to_dict(value))

# Helper: Compare two values for deep equality
static func deep_equals(a, b) -> bool:
	var a_dict = to_dict(a)
	var b_dict = to_dict(b)
	return JSON.stringify(a_dict) == JSON.stringify(b_dict)
