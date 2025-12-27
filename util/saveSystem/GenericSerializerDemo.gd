# generic_serializer_demo.gd
# Demonstration of GenericSerializer with various data types
extends Node

func _ready():
	print("=== Generic Serializer Demo ===\n")
	
	test_primitives()
	test_vectors_and_colors()
	test_nested_structures()
	test_custom_objects()
	test_complex_nested_data()
	test_dictionary_with_complex_keys()
	test_deep_copy()

func test_primitives():
	print("--- Testing Primitives ---")
	
	var test_data = {
		"string": "Hello, World!",
		"integer": 42,
		"float": 3.14159,
		"boolean": true,
		"null_value": null
	}
	
	var serialized = GenericSerializer.to_dict(test_data)
	var deserialized = GenericSerializer.from_dict(serialized)
	
	print("Original    : ", test_data)
	print("Deserialized: ", deserialized)
	print("Match: ", _compare_dicts(test_data, deserialized))
	print()

func test_vectors_and_colors():
	print("--- Testing Vectors and Colors ---")
	
	var test_data = {
		"vec2": Vector2(1.5, 2.5),
		"vec2i": Vector2i(10, 20),
		"vec3": Vector3(1.0, 2.0, 3.0),
		"color": Color(0.8, 0.2, 0.5, 1.0),
		"rect": Rect2(Vector2(0, 0), Vector2(100, 50)),
		"transform": Transform2D(0.0, Vector2(10, 20))
	}
	
	var serialized = GenericSerializer.to_dict(test_data)
	var deserialized = GenericSerializer.from_dict(serialized)
	
	print("Original vec2    : ", test_data["vec2"])
	print("Deserialized vec2: ", deserialized["vec2"])
	print("Match: ", test_data["vec2"] == deserialized["vec2"])
	
	print("Original color    : ", test_data["color"])
	print("Deserialized color: ", deserialized["color"])
	print("Match: ", test_data["color"].is_equal_approx(deserialized["color"]))
	print()

func test_nested_structures():
	print("--- Testing Nested Structures ---")
	
	var test_data = {
		"level1": {
			"level2": {
				"level3": {
					"deep_array": [1, 2, 3, [4, 5, [6, 7]]],
					"deep_value": "nested string"
				}
			}
		},
		"array_of_dicts": [
			{"name": "Item1", "value": 10},
			{"name": "Item2", "value": 20},
			{"name": "Item3", "value": 30}
		]
	}
	
	var serialized = GenericSerializer.to_dict(test_data)
	var deserialized = GenericSerializer.from_dict(serialized)
	
	print("Original deep value    : ", test_data["level1"]["level2"]["level3"]["deep_value"])
	print("Deserialized deep value: ", deserialized["level1"]["level2"]["level3"]["deep_value"])
	print("Original array    : ", test_data["array_of_dicts"])
	print("Deserialized array: ", deserialized["array_of_dicts"])
	print()

func test_custom_objects():
	print("--- Testing Custom Objects ---")
	
	# Register classes
	LoadSystem.register_class("Character", Character)
	LoadSystem.register_class("StatusEffect", StatusEffect)
	
	var poison = StatusEffect.new(1, "Poison", {"damage": 5, "duration": 3})
	var shield = StatusEffect.new(2, "Shield", {"defense": 10})
	var hero = Character.new("Hero", 100, [poison, shield])
	
	var test_data = {
		"character": hero,
		"effects": [poison, shield],
		"mixed": {
			"position": Vector2(100, 200),
			"character": hero,
			"metadata": {
				"created": "2024-01-01",
				"version": 1
			}
		}
	}
	
	var serialized = GenericSerializer.to_dict(test_data)
	print("Serialized character: ", serialized["data"]["character"])
	
	var deserialized = GenericSerializer.from_dict(serialized)
	print("Deserialized character name: ", deserialized["character"].name)
	print("Deserialized character HP: ", deserialized["character"].hp)
	print("Deserialized character effects: ", deserialized["character"].status_effects.size())
	
	# Verify nested character
	print("Nested character name: ", deserialized["mixed"]["character"].name)
	print("Nested position: ", deserialized["mixed"]["position"])
	print()

func test_complex_nested_data():
	print("--- Testing Complex Nested Data ---")
	
	# Create a deeply nested structure with mixed types
	var test_data = {
		"game_state": {
			"players": [
				{
					"name": "Player1",
					"position": Vector3(10, 0, 5),
					"inventory": {
						"gold": 500,
						"items": [
							{"id": 1, "name": "Sword", "damage": 10},
							{"id": 2, "name": "Potion", "healing": 50}
						]
					},
					"stats": {
						"hp": 100,
						"mp": 50,
						"buffs": ["strength", "agility"]
					}
				},
				{
					"name": "Player2",
					"position": Vector3(15, 0, 8),
					"inventory": {
						"gold": 300,
						"items": []
					},
					"stats": {
						"hp": 80,
						"mp": 70,
						"buffs": ["wisdom"]
					}
				}
			],
			"world": {
				"time": 12.5,
				"weather": "sunny",
				"entities": [
					{"type": "tree", "pos": Vector2(100, 100)},
					{"type": "rock", "pos": Vector2(150, 120)}
				]
			}
		}
	}
	
	var serialized = GenericSerializer.to_dict(test_data)
	var deserialized = GenericSerializer.from_dict(serialized)
	
	print("Player 1 name: ", deserialized["game_state"]["players"][0]["name"])
	print("Player 1 position: ", deserialized["game_state"]["players"][0]["position"])
	print("Player 1 gold: ", deserialized["game_state"]["players"][0]["inventory"]["gold"])
	print("Player 1 first item: ", deserialized["game_state"]["players"][0]["inventory"]["items"][0]["name"])
	print("World weather: ", deserialized["game_state"]["world"]["weather"])
	print("First entity type: ", deserialized["game_state"]["world"]["entities"][0]["type"])
	print()

func test_dictionary_with_complex_keys():
	print("--- Testing Dictionary with Complex Keys ---")
	
	# Dictionary with non-string keys
	var test_data = {}
	test_data[42] = "integer key"
	test_data[3.14] = "float key"
	test_data[Vector2i(5, 10)] = "Vector2i key"
	test_data["normal"] = "string key"
	
	var serialized = GenericSerializer.to_dict(test_data)
	print("Serialized keys: ", serialized["data"].keys())
	
	var deserialized = GenericSerializer.from_dict(serialized)
	print("Deserialized [42]: ", deserialized.get(42))
	print("Deserialized [3.14]: ", deserialized.get(3.14))
	print("Deserialized [Vector2i(5,10)]: ", deserialized.get(Vector2i(5, 10)))
	print("Deserialized ['normal']: ", deserialized.get("normal"))
	print()

func test_deep_copy():
	print("--- Testing Deep Copy ---")
	
	var original = {
		"name": "Original",
		"data": {
			"values": [1, 2, 3],
			"position": Vector2(100, 200)
		}
	}
	
	var copied = GenericSerializer.deep_copy(original)
	
	# Modify the copy
	copied["name"] = "Modified"
	copied["data"]["values"].append(4)
	copied["data"]["position"] = Vector2(300, 400)
	
	print("Original name: ", original["name"])
	print("Copied name: ", copied["name"])
	print("Original values: ", original["data"]["values"])
	print("Copied values: ", copied["data"]["values"])
	print("Original position: ", original["data"]["position"])
	print("Copied position: ", copied["data"]["position"])
	print()

func _compare_dicts(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	
	for key in a.keys():
		if not b.has(key):
			return false
		if a[key] != b[key]:
			return false
	
	return true

# Additional example: Save and load with GenericSerializer
func example_save_with_generic_serializer():
	print("--- Save/Load with GenericSerializer ---")
	
	# Create complex data
	var game_data = {
		"save_version": 1,
		"player_data": {
			"name": "Hero",
			"position": Vector3(10, 0, 5),
			"stats": {
				"hp": 100,
				"mp": 50
			}
		},
		"world_state": {
			"time": 12.5,
			"entities": [
				{"type": "npc", "pos": Vector2(100, 100)},
				{"type": "enemy", "pos": Vector2(200, 150)}
			]
		}
	}
	
	# Serialize
	var serialized = GenericSerializer.to_dict(game_data)
	
	# Save using SaveSystem
	var save_data = [serialized]
	SaveSystem.save_game(save_data, "generic_test", "data/game_state.dat")
	
	# Load using LoadSystem
	var loaded_data = LoadSystem.load_game("generic_test", "data/game_state.dat")
	
	if loaded_data.size() > 0:
		# Deserialize
		var deserialized = GenericSerializer.from_dict(loaded_data[0])
		
		print("Loaded player name: ", deserialized["player_data"]["name"])
		print("Loaded player position: ", deserialized["player_data"]["position"])
		print("Loaded world time: ", deserialized["world_state"]["time"])
