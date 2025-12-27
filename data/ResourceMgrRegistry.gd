extends Node

var resource_managers = ResourceMgr.resource_managers

func _init() -> void:
	ResourceMgr.new("res://data/SpellFormTile", ".json", SpellFormTile, false)
	ResourceMgr.new("res://data/SpellDomain", ".json", SpellDomain, false)
