class_name SpellFormTile
extends RegisteredObject

var effects: Array[String] = []
var domain: SpellDomain

func _init(p_effects: Array[String] = [], p_domain = null) -> void:
	effects = p_effects.duplicate()
	domain = p_domain
