# A flexible resource loading system that recursively searches directories
# and provides singleton/clone loading with filtering capabilities
class_name ResourceMgr
extends Node

static var resource_managers:Dictionary[String, ResourceMgr] = {}

static func get_manager_for(className) -> ResourceMgr:
	if className is Script:
		className = className.get_global_name()
	return resource_managers.get(className, null)

static func register_manager(className, mgr:ResourceMgr):
	if className is Script:
		className = className.get_global_name()
	resource_managers[className] = mgr

static func load_clone(className, objectPath:String) -> Variant:
	return get_manager_for(className)._load_clone(objectPath)

static func load_singleton(className, objectPath:String) -> Variant:
	return get_manager_for(className)._load_singleton(objectPath)

# Configuration - override these in subclasses
var base_path: String = ""
var file_suffix: String = ".json"
var resource_class = null  # The class to instantiate
var validate_on_index: bool = false  # If true, validate files during indexing

# Internal state
var _file_paths: Array[String] = []
var _singleton_cache: Dictionary = {}  # path -> instance
var _indexed: bool = false

# Initialize with configuration
func _init(p_base_path: String = "", p_file_suffix: String = ".json", p_resource_class = null, p_validate_on_index: bool = false) -> void:
	base_path = p_base_path
	file_suffix = p_file_suffix
	resource_class = p_resource_class
	validate_on_index = p_validate_on_index
	if resource_class:
		register_manager(resource_class.get_global_name(), self)

# Index the directory to find all matching files
func index() -> void:
	if _indexed:
		return
	
	_file_paths.clear()
	_scan_directory(base_path)
	_indexed = true

# Recursively scan directory for files with matching suffix
func _scan_directory(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		push_warning("Directory does not exist: " + dir_path)
		return
	
	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_error("Failed to open directory: " + dir_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = dir_path.path_join(file_name)
		var relative_path_without_suffix = get_path_without_suffix(file_name)
		
		if dir.current_is_dir():
			# Recursively scan subdirectories, skip hidden dirs
			if not file_name.begins_with("."):
				_scan_directory(full_path)
		else:
			# Check if file matches our suffix
			if file_name.ends_with(file_suffix):
				# Optionally validate the file by attempting to load it
				if validate_on_index:
					if _validate_file(full_path):
						_file_paths.append(relative_path_without_suffix)
					# If validation fails, file is skipped (error already logged)
				else:
					_file_paths.append(relative_path_without_suffix)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

# Validate a file by attempting to create a clone from it
func _validate_file(file_path: String) -> bool:
	var instance = _load_from_file(file_path)
	
	if instance == null:
		push_error("Failed to validate file during indexing: " + file_path + " (could not load)")
		return false
	
	# File loaded successfully, discard the test instance
	return true

# Get all indexed file paths
func get_all_paths() -> Array[String]:
	if not _indexed:
		index()
	return _file_paths.duplicate()

# Load a resource as a singleton (cached instance)
func _load_singleton(path: String) -> Variant:
	if not _indexed:
		index()
	
	# Normalize path (add suffix if missing)
	var normalized_path = _normalize_path(path)
	
	# Check cache first
	if _singleton_cache.has(normalized_path):
		return _singleton_cache[normalized_path]
	
	# Load and cache
	var instance = _load_from_file(normalized_path)
	if instance != null:
		_singleton_cache[normalized_path] = instance
	
	return instance

# Load a resource as a clone (fresh copy each time)
func _load_clone(path: String) -> Variant:
	if not _indexed:
		index()
	
	var normalized_path = _normalize_path(path)
	return _load_from_file(normalized_path)

# Normalize path by adding base_path and suffix if needed
func _normalize_path(path: String) -> String:
	var result = path
	
	# Add base_path if path is relative
	if not result.is_absolute_path():
		result = base_path.path_join(result)
	
	# Add suffix if missing
	if not result.ends_with(file_suffix):
		result += file_suffix
	
	return result

# Load instance from JSON file
func _load_from_file(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		push_warning("File not found: " + file_path)
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse JSON in " + file_path + ": " + json.get_error_message())
		return null
	
	var data = json.get_data()
	return _instantiate_from_data(data)

# Instantiate resource from parsed data
func _instantiate_from_data(data) -> Variant:
	if resource_class == null:
		push_error("No resource_class configured")
		return null
	var instance = GenericSerializer.from_dict(data)
	if instance is RegisteredObject:
		instance = instance.get_canonical()
	return instance

# Filter paths by prefix
func filter_by_prefix(prefix: String) -> Array[String]:
	if not _indexed:
		index()
	
	var results: Array[String] = []
	var search_prefix = base_path.path_join(prefix)
	
	for path in _file_paths:
		if path.begins_with(search_prefix):
			results.append(path)
	
	return results

# Filter paths by regular expression
func filter_by_regex(pattern: String) -> Array[String]:
	if not _indexed:
		index()
	
	var regex = RegEx.new()
	var error = regex.compile(pattern)
	if error != OK:
		push_error("Invalid regex pattern: " + pattern)
		return []
	
	var results: Array[String] = []
	
	for path in _file_paths:
		if regex.search(path) != null:
			results.append(path)
	
	return results

# Clear singleton cache (useful for hot-reloading)
func clear_cache() -> void:
	_singleton_cache.clear()

# Force re-indexing on next access
func invalidate_index() -> void:
	_indexed = false
	_file_paths.clear()

# Get relative path from base_path
func get_relative_path(full_path: String) -> String:
	if full_path.begins_with(base_path):
		var relative = full_path.substr(base_path.length())
		if relative.begins_with("/"):
			relative = relative.substr(1)
		return relative
	return full_path

# Get path without suffix
func get_path_without_suffix(path: String) -> String:
	if path.ends_with(file_suffix):
		return path.substr(0, path.length() - file_suffix.length())
	return path

func load_all_data() -> Dictionary:
	var result = {}
	for path in get_all_paths():
		result[path] = _load_clone(path)
	return result

func _save_to_file(path:String, data, indent_char="\t") -> void:
	var file = FileAccess.open(base_path.path_join(path + file_suffix), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, indent_char))
		file.close()

func save_all_data(path_to_data_dict:Dictionary) -> void:
	for path in path_to_data_dict:
		var data_to_save = GenericSerializer.to_dict(path_to_data_dict[path], true)
		_save_to_file(path, data_to_save)
