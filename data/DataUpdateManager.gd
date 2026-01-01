# Allows for easy updating of the data files
extends Node

func _ready():
	update_SpellDomain()
	update_SpellFormTile()

# Use this to avoid updating an existing RegisteredObject's ID, for example
func get_or_clone(entry_name:String, classRef, path_prefix:String, resourceMgr:ResourceMgr, data) -> Variant:
	var path = path_prefix + entry_name
	var result = resourceMgr._load_singleton(path)
	if result == null:
		result = classRef.new()
	if result is RegisteredObject:
		result.id = entry_name
	data[path] = result
	return result

func update_SpellDomain():
	## Update these
	var classRef = SpellDomain
	var entry:SpellDomain
	## Leave these alone
	var mgr = ResourceMgr.get_manager_for(classRef)
	var data = mgr.load_all_data()
	var prefix = ""

	## Update with new data if needed
	entry = get_or_clone("BLOCKED", classRef, prefix, mgr, data)
	entry.domain_name = "BLOCKED"
	#entry = get_or_clone("dark", classRef, prefix, mgr, data)
	#entry.domain_name = "Dark"
	#entry = get_or_clone("poison", classRef, prefix, mgr, data)
	#entry.domain_name = "Poison"
	
	# Save existing data
	mgr.save_all_data(data)

func update_SpellFormTile():
	## Update these
	var classRef = SpellFormTile
	var entry:SpellFormTile
	## Leave these alone
	var mgr = ResourceMgr.get_manager_for(classRef)
	var data = mgr.load_all_data()
	var prefix = ""
	var spellDomainMgr := ResourceMgr.get_manager_for(SpellDomain)

	## Update with new data if needed
	entry = get_or_clone("optical_refraction", classRef, prefix, mgr, data)
	entry.category = "consensus"

	entry.integration_max = 5
	var adj_effect := AdjacencyEffect.new()
	adj_effect.effect_type = "resource_delta"
	adj_effect.resource = "cohesion"
	adj_effect.amount = 1
	adj_effect.target_tag = "consensus"
	adj_effect.conditions = {"min_integration": 1}
	adj_effect.extras = {"note": "Bonus for neighboring consensus tiles"}
	entry.outgoing_adjacency_effects = [adj_effect]
	
	var synergy := SynergyEffect.new()
	synergy.pattern = ["consensus", "tenuous"]
	synergy.unlock_at_integration = 3
	synergy.effect_type = "resource_delta"
	synergy.resource = "efficiency"
	synergy.amount = 2
	synergy.extras = {
		"note": "Optical synergy activated",
	}
	entry.synergies = [synergy]

	
	# Save existing data
	mgr.save_all_data(data)
	pass
