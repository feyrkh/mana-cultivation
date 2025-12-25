# Character.gd
class_name Character
extends RefCounted

var name: String
var hp: int
var status_effects: Array[StatusEffect]

func _init(p_name: String = "", p_hp: int = 100, p_effects: Array[StatusEffect] = []) -> void:
	name = p_name
	hp = p_hp
	status_effects = p_effects.duplicate()

# Lifecycle hooks
func pre_save() -> void:
	pass

func post_save() -> void:
	pass

func pre_load() -> void:
	pass

func post_load() -> void:
	pass

# Serialize to dictionary
func to_dict() -> Dictionary:
	pre_save()
	var effects_data: Array = []
	for effect in status_effects:
		effects_data.append(effect.to_dict())
	
	var result = {
		"__class__": "Character",
		"name": name,
		"hp": hp,
		"status_effects": effects_data
	}
	post_save()
	return result

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> Character:
	var character = Character.new()
	character.pre_load()
	character.name = dict.get("name", "")
	character.hp = dict.get("hp", 100)
	
	var effects_data: Array = dict.get("status_effects", [])
	for effect_dict in effects_data:
		if effect_dict is Dictionary:
			character.status_effects.append(StatusEffect.from_dict(effect_dict))
	
	character.post_load()
	return character
