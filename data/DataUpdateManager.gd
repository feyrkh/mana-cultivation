# Allows for easy updating of the data files
extends Node

func _ready():
	#update_SpellDomain()
	update_SpellFormTile()

# Use this to avoid updating an existing RegisteredObject's ID, for example
func get_or_clone(entry_name:String, classRef, path_prefix:String, resourceMgr:ResourceMgr, data) -> Variant:
	var path = path_prefix + entry_name
	var result = resourceMgr.load_singleton(path)
	if result == null:
		result = classRef.new()
	data[path] = result
	return result

func update_SpellDomain():
	## Update these
	var mgr = SpellDomainMgr
	var classRef = SpellDomain
	var entry:SpellDomain
	## Leave these alone
	var data = mgr.load_all_data()
	var prefix = ""

	## Update with new data if needed
	#entry = get_or_clone("light", classRef, prefix, mgr, data)
	#entry.domain_name = "Light"
	#entry = get_or_clone("dark", classRef, prefix, mgr, data)
	#entry.domain_name = "Dark"
	#entry = get_or_clone("poison", classRef, prefix, mgr, data)
	#entry.domain_name = "Poison"
	
	# Save existing data
	mgr.save_all_data(data)

func update_SpellFormTile():
	## Update these
	var mgr = SpellFormTileMgr
	var classRef = SpellFormTile
	var entry:SpellFormTile
	## Leave these alone
	var data = mgr.load_all_data()
	var prefix = ""

	## Update with new data if needed
	entry = get_or_clone("ponder", classRef, prefix, mgr, data)
	#entry.domain = SpellDomainMgr.load_singleton("light")
	
	# Save existing data
	mgr.save_all_data(data)
