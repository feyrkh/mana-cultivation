class_name SpellformTile
extends RefCounted

var effects: Array[String] = []
var domain: SpellDomain

func _init(p_effects: Array[String] = []) -> void:
	effects = p_effects.duplicate()
