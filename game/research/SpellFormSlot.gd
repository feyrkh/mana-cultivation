class_name SpellFormSlot
extends RefCounted

var spell_form_tile:SpellFormTile
var adjacent_tiles:Array[SpellFormTile] = []
var inertia := 0
var integration := 0
