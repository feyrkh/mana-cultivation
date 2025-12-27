class_name DemoInventory 
extends RefCounted
var gold: int = 0
var weapons: Array = []
var items: Dictionary = {}

func _init(p_gold: int = 0):
	gold = p_gold
