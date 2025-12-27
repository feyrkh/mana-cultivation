class_name DemoEnemy
extends RefCounted

var enemy_name: String = ""
var health: int = 100
var damage: int = 10
var position: Vector2 = Vector2.ZERO
var is_alive: bool = true

func _init(p_name: String = "", p_health: int = 100):
	enemy_name = p_name
	health = p_health
