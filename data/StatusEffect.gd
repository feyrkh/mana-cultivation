# StatusEffect.gd
class_name StatusEffect
extends RefCounted

static func _static_init() -> void:
	LoadSystem.register_class("StatusEffect", StatusEffect)

static var DEFAULT_SCHEMA:Dictionary[String, FormFieldSchema] = {
	"id": FormFieldSchema.int_field().with_readonly(true),
	"data": FormFieldSchema.custom_scene_field("res://modelRenderSystem/DictionaryFormBuilder.tscn")
}
func get_schema() -> Dictionary[String, FormFieldSchema]:
	return DEFAULT_SCHEMA

var id: int
var display_name: String
var data: Dictionary

func _init(p_id: int = 0, p_display_name: String = "", p_data: Dictionary = {}) -> void:
	id = p_id
	display_name = p_display_name
	data = p_data.duplicate(true)
