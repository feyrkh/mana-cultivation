class_name SpellFormSlot
extends RefCounted

var spell_form_tile:SpellFormTile
var adjacent_tiles:Array[SpellFormTile] = []
var inertia := 0
var integration := 0

# Validation callable for drag-drop. Override to restrict which tiles can be placed.
var can_accept_tile: Callable = func(tile: SpellFormTile) -> bool: return true
