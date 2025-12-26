# StatusEffect.gd
class_name StatusEffect
extends RefCounted

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

# Lifecycle hooks for save/load
func pre_save() -> void:
	# Called before saving - override in subclasses if needed
	pass

func post_save() -> void:
	# Called after saving - override in subclasses if needed
	pass

func pre_load() -> void:
	# Called before loading - override in subclasses if needed
	pass

func post_load() -> void:
	# Called after loading - override in subclasses if needed
	pass

# Serialize to dictionary
func to_dict() -> Dictionary:
	pre_save()
	var result = {
		"__class__": "StatusEffect",
		"id": id,
		"display_name": display_name,
		"data": data.duplicate(true)
	}
	post_save()
	return result

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> StatusEffect:
	var effect = StatusEffect.new()
	effect.pre_load()
	effect.id = dict.get("id", 0)
	effect.display_name = dict.get("display_name", "")
	effect.data = dict.get("data", {}).duplicate(true)
	effect.post_load()
	return effect
