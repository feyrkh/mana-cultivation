extends Node

@onready var spellform_tile_list:SpellFormTileList = find_child("SpellformTileList")
@onready var spellform_tile_details:AutoFormBuilder = find_child("SpellformTileDetails")

func _ready():
	spellform_tile_list.spellform_tiles = [
		ResourceMgr.load_clone(SpellFormTile, "ponder"),
		ResourceMgr.load_clone(SpellFormTile, "optical_refraction"),
	]
	spellform_tile_list.spellform_tile_clicked.connect(on_button_click)
	spellform_tile_list.spellform_tile_hovered.connect(on_button_hover)
	spellform_tile_list.spellform_tile_unhovered.connect(on_button_unhover)

func on_button_hover(tile:SpellFormTile, idx:int) -> void:
	var adjacency_notes: Array[String] = []
	for effect in tile.outgoing_adjacency_effects:
		adjacency_notes.append(effect.extras.get("note", ""))
	var synergy_notes: Array[String] = []
	for synergy in tile.synergies:
		synergy_notes.append(synergy.extras.get("note", ""))

	var display_data = {
		"id": tile.id,
		"category": tile.category,
		"integration_max": tile.integration_max,
		"inertia_max": tile.inertia_max,
		"adjacency_effects": adjacency_notes,
		"synergies": synergy_notes
	}

	var schema: Dictionary[String, FormFieldSchema] = {
		"id": FormFieldSchema.readonly_field("ID"),
		"category": FormFieldSchema.readonly_field("Category"),
		"integration_max": FormFieldSchema.readonly_field("Max Integration"),
		"inertia_max": FormFieldSchema.readonly_field("Max Inertia"),
		"adjacency_effects": FormFieldSchema.readonly_field("Adjacency Effects"),
		"synergies": FormFieldSchema.readonly_field("Synergies")
	}

	spellform_tile_details.show_models({"tile": display_data}, {"tile": schema})
func on_button_unhover(tile:SpellFormTile, idx:int) -> void:
	pass

func on_button_click(tile:SpellFormTile, idx:int) -> void:
	pass
