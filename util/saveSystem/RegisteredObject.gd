# RegisteredObject.gd
# Base class for objects that have IDs managed by the InstanceRegistry
class_name RegisteredObject
extends RefCounted

# The ID of this instance (-1 means unassigned)
var id: int = -1

# Get the type name for this class (override in subclasses for custom type names)
func get_type_name() -> String:
	return get_script().get_global_name()

# Get the ID of this instance, assigning one if needed
func get_id() -> int:
	if id == -1:
		_assign_new_id()
	return id

# Check if this instance has been assigned an ID
func has_id() -> bool:
	return id != -1

# Assign a new ID from the registry
func _assign_new_id() -> void:
	var registry = InstanceRegistry.get_registry()
	id = registry.generate_id(get_type_name())
	registry.register_instance(get_type_name(), id, self)

# Set the ID directly (used during deserialization)
func _set_id(id: int) -> void:
	if id != -1 and id != id:
		# Unregister old ID
		var registry = InstanceRegistry.get_registry()
		registry.unregister_instance(get_type_name(), id)
	
	id = id
	
	if id != -1:
		# Register with new ID
		var registry = InstanceRegistry.get_registry()
		registry.register_instance(get_type_name(), id, self)

# Get the canonical instance for this ID, or self if this is canonical
func get_canonical() -> RegisteredObject:
	if id == -1:
		_assign_new_id()
		return self
	
	var registry = InstanceRegistry.get_registry()
	var canonical = registry.get_instance(get_type_name(), id)
	
	if canonical == null:
		# We are the canonical instance
		registry.register_instance(get_type_name(), id, self)
		return self
	
	return canonical

# Serialize to dictionary
func to_dict() -> Dictionary:
	var result = {
		"__class__": get_type_name(),
		"__id__": get_id()  # Ensure ID is assigned before saving
	}
	return result

# Deserialize from dictionary and return canonical instance
# Assumes that the saved instance registry has also been restored
static func from_dict(dict: Dictionary) -> RegisteredObject:
	return InstanceRegistry.get_registry().get_instance(dict['__class__'], dict['__id__'])

# Helper method for subclasses to use in their from_dict implementations
static func _resolve_canonical(obj: RegisteredObject, dict: Dictionary) -> RegisteredObject:
	# Set the ID from the dictionary
	var loaded_id = dict.get("__id__", -1)
	
	if loaded_id != -1:
		var registry = InstanceRegistry.get_registry()
		
		# Check if canonical instance already exists
		if registry.has_instance(obj.get_type_name(), loaded_id):
			# Return the canonical instance instead
			var canonical = registry.get_instance(obj.get_type_name(), loaded_id)
			return canonical
		else:
			# We are the first instance with this ID, register as canonical
			obj._set_id(loaded_id)
	return obj
