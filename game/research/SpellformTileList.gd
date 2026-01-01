class_name SpellFormTileList
extends VBoxContainer

signal spellform_tile_hovered(tile:SpellFormTile, idx:int)
signal spellform_tile_unhovered(tile:SpellFormTile, idx:int)
signal spellform_tile_clicked(tile:SpellFormTile, idx:int)

@onready var button_populator := ButtonListPopulator.new(self, [], "{id}")
var spellform_tiles:Array[SpellFormTile] = []:
	set(v):
		if v != spellform_tiles:
			spellform_tiles = v
			refresh()

func _ready() -> void:
	button_populator.set_objects(spellform_tiles)
	button_populator.button_hovered.connect(func(object, idx): spellform_tile_hovered.emit(object, idx))
	button_populator.button_unhovered.connect(func(object, idx): spellform_tile_unhovered.emit(object, idx))
	button_populator.button_clicked.connect(func(object, idx): spellform_tile_clicked.emit(object, idx))
	refresh()

func refresh() -> void:
	button_populator.set_objects(spellform_tiles)
