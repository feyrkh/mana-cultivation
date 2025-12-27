class_name DemoWeapon
extends RefCounted

var weapon_name: String = ""
var attack_power: int = 0
var durability: float = 1.0
var element: String = "physical"

func _init(p_name: String = "", p_power: int = 0):
	weapon_name = p_name
	attack_power = p_power
