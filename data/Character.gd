# Character.gd
class_name Character
extends RefCounted

static func _static_init() -> void:
	LoadSystem.register_class("Character", Character)

static var DEFAULT_SCHEMA:Dictionary[String, FormFieldSchema] = {
	"status_effects": FormFieldSchema.array_field(StatusEffect.DEFAULT_SCHEMA).with_readonly(true),
	"hp": FormFieldSchema.int_field().with_hidden(false)
}
func get_schema() -> Dictionary[String, FormFieldSchema]:
	return DEFAULT_SCHEMA

var name: String
var hp: int
var status_effects: Array[StatusEffect]

func _init(p_name: String = "", p_hp: int = 100, p_effects: Array[StatusEffect] = []) -> void:
	name = p_name
	hp = p_hp
	status_effects = p_effects.duplicate()
