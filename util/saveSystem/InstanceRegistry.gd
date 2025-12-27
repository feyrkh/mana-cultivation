# Central registry for managing canonical instances of objects by type and ID
class_name InstanceRegistry
extends RefCounted

# Singleton instance
static var _instance: InstanceRegistry = null

# Registry structure: { type_name: { id: instance } }
var registry: Dictionary = {}

# ID counters per type: { type_name: next_id }
var id_counters: Dictionary = {}

# Get singleton instance
static func get_registry() -> InstanceRegistry:
	if _instance == null:
		_instance = InstanceRegistry.new()
	return _instance

static func set_registry(new_registry:InstanceRegistry) -> void:
	_instance = new_registry

# Register an instance with its type and ID
func register_instance(type_name: String, id: int, instance) -> void:
	if not registry.has(type_name):
		registry[type_name] = {}
	
	registry[type_name][id] = instance

# Get a registered instance by type and ID
func get_instance(type_name: String, id: int):
	if not registry.has(type_name):
		return null
	
	return registry[type_name].get(id, null)

# Check if an instance with this type and ID exists
func has_instance(type_name: String, id: int) -> bool:
	if not registry.has(type_name):
		return false
	
	return registry[type_name].has(id)

# Generate a new ID for a type
func generate_id(type_name: String) -> int:
	if not id_counters.has(type_name):
		id_counters[type_name] = 1
	
	var new_id = id_counters[type_name]
	id_counters[type_name] += 1
	return new_id

# Unregister an instance
func unregister_instance(type_name: String, id: int) -> void:
	if registry.has(type_name):
		registry[type_name].erase(id)
		
		# Clean up empty type dictionaries
		if registry[type_name].is_empty():
			registry.erase(type_name)

# Clear all instances of a type
func clear_type(type_name: String) -> void:
	registry.erase(type_name)

# Clear the entire registry
func clear_all() -> void:
	registry.clear()
	id_counters.clear()

# Get all instances of a type
func get_all_instances(type_name: String) -> Array:
	if not registry.has(type_name):
		return []
	
	var instances: Array = []
	for id in registry[type_name]:
		instances.append(registry[type_name][id])
	
	return instances

# Get count of registered instances for a type
func get_instance_count(type_name: String) -> int:
	if not registry.has(type_name):
		return 0
	
	return registry[type_name].size()

# Debug: Print registry contents
func print_registry() -> void:
	print("=== Instance Registry ===")
	for type_name in registry:
		print("Type: " + type_name)
		for id in registry[type_name]:
			print("  ID " + str(id) + ": " + str(registry[type_name][id]))
