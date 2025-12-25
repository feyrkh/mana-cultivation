# Example usage in a game scene or autoload
extends Node

func _ready():
	example_save_and_load()

func example_save_and_load():
	# Create some status effects
	var poison = StatusEffect.new(1, "Poison", {"damage_per_turn": 5, "duration": 3})
	var shield = StatusEffect.new(2, "Shield", {"defense_bonus": 10})
	
	# Create a character with status effects
	var hero = Character.new("Hero", 100, [poison, shield])
	var enemy = Character.new("Goblin", 50, [])
	
	# Save the characters
	var characters_to_save: Array = [hero, enemy]
	#var save_success = SaveSystem.save_game(
		#characters_to_save,
		#"save_slot_1",
		#"characters/party.dat"
	#)
	#
	#if save_success:
		#print("Game saved successfully!")
	
	# Load the characters back
	var loaded_characters = LoadSystem.load_game(
		"save_slot_1",
		"characters/party.dat"
	)
	
	if loaded_characters.size() > 0:
		print("Game loaded successfully!")
		for character in loaded_characters:
			if character is Character:
				print("Loaded: " + character.name + " with HP: " + str(character.hp))
				for effect in character.status_effects:
					print("  - " + effect.display_name + ": " + str(effect.data))

# Example of custom lifecycle hooks
class CustomCharacter extends Character:
	var temporary_data = []
	
	func pre_save():
		print("Preparing " + name + " for save...")
		# Could clean up temporary data here
		temporary_data.clear()
	
	func post_save():
		print(name + " saved!")
	
	func pre_load():
		print("Preparing to load character...")
	
	func post_load():
		print(name + " loaded!")
		# Could initialize temporary runtime data here
		temporary_data = []

# To switch between JSON and binary, change USE_JSON_FORMAT in SaveLoadConfig.gd
# JSON format is human-readable but larger
# Binary format is compact but not human-readable

# The system automatically:
# - Creates directories as needed
# - Handles nested objects, arrays, and dictionaries
# - Autodetects file format on load
# - Calls lifecycle hooks at appropriate times
# - Preserves class information for proper deserialization
