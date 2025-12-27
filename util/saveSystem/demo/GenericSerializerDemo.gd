# reflection_demo.gd
# Demonstrates automatic serialization/deserialization without to_dict/from_dict
extends Node

func _ready():
	print("=== Reflection-Based Serialization Demo ===\n")
	
	#demo_1_simple_object()
	#demo_2_nested_objects()
	#demo_3_mixed_approaches()
	demo_4_save_load_workflow()
	demo_5_complex_game_state()

# Demo 1: Simple object without to_dict/from_dict
func demo_1_simple_object():
	print("--- Demo 1: Simple Object (No to_dict/from_dict) ---")
	
	var enemy = DemoEnemy.new("Goblin", 50)
	enemy.damage = 15
	enemy.position = Vector2(100, 200)
	
	print("Original enemy:")
	print("  Name: ", enemy.enemy_name)
	print("  Health: ", enemy.health)
	print("  Damage: ", enemy.damage)
	print("  Position: ", enemy.position)
	
	# Serialize using reflection
	var serialized = GenericSerializer.to_dict(enemy)
	print("\nSerialized: ", serialized)
	
	# Deserialize using reflection
	var restored = GenericSerializer.from_dict(serialized)
	
	print("\nRestored enemy:")
	print("  Name: ", restored.enemy_name)
	print("  Health: ", restored.health)
	print("  Damage: ", restored.damage)
	print("  Position: ", restored.position)
	print("  Type check: ", restored is DemoEnemy)
	print()

# Demo 2: Nested objects without to_dict/from_dict
func demo_2_nested_objects():
	print("--- Demo 2: Nested Objects (No to_dict/from_dict) ---")
	
	var sword = DemoWeapon.new("Iron Sword", 25)
	sword.durability = 0.8
	sword.element = "fire"
	
	var axe = DemoWeapon.new("Battle Axe", 35)
	axe.element = "earth"
	
	var inventory = DemoInventory.new(500)
	inventory.weapons = [sword, axe]
	inventory.items = {
		"health_potion": 5,
		"mana_potion": 3
	}
	
	print("Original inventory:")
	print("  Gold: ", inventory.gold)
	print("  DemoWeapons: ", inventory.weapons.size())
	print("  First weapon: ", inventory.weapons[0].weapon_name, " (", inventory.weapons[0].attack_power, " dmg)")
	print("  Items: ", inventory.items)
	
	# Serialize
	var serialized = GenericSerializer.to_dict(inventory)
	
	# Deserialize
	var restored = GenericSerializer.from_dict(serialized)
	
	print("\nRestored inventory:")
	print("  Gold: ", restored.gold)
	print("  DemoWeapons: ", restored.weapons.size())
	print("  First weapon: ", restored.weapons[0].weapon_name, " (", restored.weapons[0].attack_power, " dmg)")
	print("  Second weapon element: ", restored.weapons[1].element)
	print("  Items: ", restored.items)
	print("  Type check: ", restored is DemoInventory)
	print("  DemoWeapon type check: ", restored.weapons[0] is DemoWeapon)
	print()

# Demo 3: Mixed approaches (some with to_dict, some without)
func demo_3_mixed_approaches():
	print("--- Demo 3: Mixed Approaches ---")
	
	# Character has to_dict/from_dict
	var poison = StatusEffect.new(1, "Poison", {"damage": 5})
	var hero = Character.new("Hero", 100, [poison])
	
	# DemoWeapon does NOT have to_dict/from_dict
	var weapon = DemoWeapon.new("Magic Staff", 40)
	weapon.element = "lightning"
	
	# Enemy does NOT have to_dict/from_dict
	var enemy = DemoEnemy.new("Boss", 500)
	enemy.position = Vector2(1000, 500)
	
	var game_data = {
		"player_character": hero,
		"player_weapon": weapon,
		"current_enemy": enemy,
		"location": "Dark Cave",
		"time": 14.5
	}
	
	print("Original data:")
	print("  Player: ", game_data["player_character"].name)
	print("  DemoWeapon: ", game_data["player_weapon"].weapon_name)
	print("  Enemy: ", game_data["current_enemy"].enemy_name)
	
	# Serialize everything
	var serialized = GenericSerializer.to_dict(game_data)
	
	# Deserialize everything
	var restored = GenericSerializer.from_dict(serialized)
	
	print("\nRestored data:")
	print("  Player: ", restored["player_character"].name, " (HP: ", restored["player_character"].hp, ")")
	print("  Player has to_dict: ", restored["player_character"] is Character)
	print("  DemoWeapon: ", restored["player_weapon"].weapon_name, " (", restored["player_weapon"].element, ")")
	print("  DemoWeapon uses reflection: ", restored["player_weapon"] is DemoWeapon)
	print("  Enemy: ", restored["current_enemy"].enemy_name, " (HP: ", restored["current_enemy"].health, ")")
	print("  Enemy uses reflection: ", restored["current_enemy"] is DemoEnemy)
	print("  Location: ", restored["location"])
	print()

# Demo 4: Save/Load workflow
func demo_4_save_load_workflow():
	print("--- Demo 4: Save/Load Workflow ---")
	
	# Create data with objects that don't have to_dict
	var boss = DemoEnemy.new("Dragon", 1000)
	boss.damage = 100
	boss.position = Vector2(5000, 3000)
	
	var legendary_sword = DemoWeapon.new("Excalibur", 150)
	legendary_sword.element = "holy"
	legendary_sword.durability = 0.95
	
	var save_data = {
		"boss": boss,
		"reward": legendary_sword,
		"defeated": false
	}
	
	# Save to file
	SaveSystem.save_game(save_data, "reflection_test", "boss_state.dat")
	print("✓ Saved boss state")
	
	# Load from file
	var loaded = LoadSystem.load_game("reflection_test", "boss_state.dat")
	
	print("✓ Loaded boss state")
	print("\nBoss state:")
	print("  Name: ", loaded["boss"].enemy_name)
	print("  Health: ", loaded["boss"].health)
	print("  Damage: ", loaded["boss"].damage)
	print("  Position: ", loaded["boss"].position)
	print("\nReward:")
	print("  Name: ", loaded["reward"].weapon_name)
	print("  Power: ", loaded["reward"].attack_power)
	print("  Element: ", loaded["reward"].element)
	print()

# Demo 5: Complex game state
func demo_5_complex_game_state():
	print("--- Demo 5: Complex Game State ---")
	
	# Build a complex state with mixed object types
	var enemies = [
		DemoEnemy.new("Goblin", 50),
		DemoEnemy.new("Orc", 120),
		DemoEnemy.new("Troll", 200)
	]
	
	var loot_table = DemoInventory.new(1000)
	loot_table.weapons = [
		DemoWeapon.new("Dagger", 15),
		DemoWeapon.new("Mace", 30),
		DemoWeapon.new("Spear", 25)
	]
	loot_table.items = {
		"gem": 10,
		"scroll": 5,
		"key": 1
	}
	
	var dungeon_state = {
		"floor": 5,
		"enemies_remaining": enemies,
		"treasure": loot_table,
		"explored_rooms": [1, 2, 3, 5, 7],
		"boss_defeated": false,
		"player_position": Vector2(250, 180),
		"ambient_light": Color(0.3, 0.3, 0.4, 1.0)
	}
	
	print("Original dungeon state:")
	print("  Floor: ", dungeon_state["floor"])
	print("  Enemies: ", dungeon_state["enemies_remaining"].size())
	for i in range(dungeon_state["enemies_remaining"].size()):
		var e = dungeon_state["enemies_remaining"][i]
		print("    - ", e.enemy_name, " (HP: ", e.health, ")")
	print("  Treasure weapons: ", dungeon_state["treasure"].weapons.size())
	print("  Treasure gold: ", dungeon_state["treasure"].gold)
	
	# Save
	SaveSystem.save_game(dungeon_state, "dungeon_test", "dungeon.dat")
	
	# Load
	var loaded = LoadSystem.load_game("dungeon_test", "dungeon.dat")
	
	# Deserialize
	var restored = GenericSerializer.from_dict(loaded)
	
	print("\nRestored dungeon state:")
	print("  Floor: ", restored["floor"])
	print("  Enemies: ", restored["enemies_remaining"].size())
	for i in range(restored["enemies_remaining"].size()):
		var e = restored["enemies_remaining"][i]
		print("    - ", e.enemy_name, " (HP: ", e.health, ")")
		print("      Type: ", e is DemoEnemy)
	print("  Treasure weapons: ", restored["treasure"].weapons.size())
	for weapon in restored["treasure"].weapons:
		print("    - ", weapon.weapon_name, " (", weapon.attack_power, " dmg)")
	print("  Treasure gold: ", restored["treasure"].gold)
	print("  Player position: ", restored["player_position"])
	print("  Ambient light: ", restored["ambient_light"])
	print()

# Performance comparison
func demo_performance():
	print("--- Performance Comparison ---")
	
	var iterations = 1000
	
	# Test 1: Objects WITH to_dict
	var start_time = Time.get_ticks_msec()
	for i in range(iterations):
		var char = Character.new("Test", 100, [])
		var s = GenericSerializer.to_dict(char)
		var r = GenericSerializer.from_dict(s)
	var with_to_dict_time = Time.get_ticks_msec() - start_time
	
	# Test 2: Objects WITHOUT to_dict (reflection)
	start_time = Time.get_ticks_msec()
	for i in range(iterations):
		var enemy = DemoEnemy.new("Test", 100)
		var s = GenericSerializer.to_dict(enemy)
		var r = GenericSerializer.from_dict(s)
	var reflection_time = Time.get_ticks_msec() - start_time
	
	print("Iterations: ", iterations)
	print("With to_dict(): ", with_to_dict_time, "ms")
	print("With reflection: ", reflection_time, "ms")
	print("Overhead: ", reflection_time - with_to_dict_time, "ms (", 
		  float(reflection_time - with_to_dict_time) / iterations, "ms per object)")
