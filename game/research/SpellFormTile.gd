class_name SpellformTile
extends RefCounted

static func _static_init() -> void:
	LoadSystem.register_class("SpellformTile", SpellformTile)

var effects: Array[String] = []
	
func _init(p_effects: Array[String] = []) -> void:
	effects = p_effects.duplicate()

# Serialize to dictionary
func to_dict() -> Dictionary:
	var result = {
		"__class__": "SpellformTile",
		"effects": effects.duplicate()
	}
	return result

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> SpellformTile:
	var tile = SpellformTile.new()
	var effects_data = dict.get("effects", [])
	tile.effects.clear()
	for effect in effects_data:
		if effect is String:
			tile.effects.append(effect)
	return tile
