# AutoFormExample.gd
class_name AutoFormBuilderDemo
extends Control

func _ready():
	example_basic_usage()
	# example_with_schema()
	# example_multiple_models()

# ============================================
# Example 1: Basic Usage (No Schema)
# ============================================
func example_basic_usage():
	# Create a character
	var poison = StatusEffect.new(1, "Poison", {"damage": 5})
	var blessed = StatusEffect.new(1, "Blessed", {"holy": 5, "range": 5000})
	var hero = Character.new("Feyr", 100, [poison, blessed])
	
	# Create the auto form
	var auto_form = AutoFormBuilder.new()
	auto_form.explicit_fields_only = false
	add_child(auto_form)
	
	#auto_form.show_model("hero", hero, {})
	auto_form.show_models({"hero": hero})
	#auto_form.show_model("hero", hero, {
		#"status_effects": {
			#"show_item_buttons": true,
			#"readonly": true,
			#"item_schema": {
				#"id": {"readonly": true},
				#"data": {
					#"scene": "res://modelRenderSystem/DictionaryFormBuilder.tscn",
				#}
			#}
		#}
	#})
	
	# Connect to signals if you want to know when changes happen
	auto_form.edit_confirmed.connect(func(models): 
		print("Hero updated: ", models["hero"].name, " HP: ", models["hero"].hp)
	)

# ============================================
# Example 2: With Schema for Customization
# ============================================
func example_with_schema():
	var hero = Character.new("Feyr", 100, [])
	
	# Define a schema to customize specific fields
	var schema = {
		"name": {
			"label": "Character Name",
			"type": "string"
		},
		"hp": {
			"label": "Health Points",
			"type": "int",
			"min": 0,
			"max": 999
		},
		"status_effects": {
			"label": "Status Effects",
			"readonly": true  # Mark as readonly
		}
	}
	
	var auto_form = AutoFormBuilder.new()
	add_child(auto_form)
	
	auto_form.show_model("hero", hero, schema)

# ============================================
# Example 3: Multiple Models
# ============================================
func example_multiple_models():
	var hero = Character.new("Feyr", 100, [])
	var enemy = Character.new("Goblin", 50, [])
	
	var models = {
		"hero": hero,
		"enemy": enemy
	}
	
	# Optional: schemas for each model
	var schemas = {
		"hero": {
			"hp": {"min": 0, "max": 999}
		},
		"enemy": {
			"hp": {"min": 0, "max": 500}
		}
	}
	
	var auto_form = AutoFormBuilder.new()
	add_child(auto_form)
	
	auto_form.show_models(models, schemas)

# ============================================
# Example 4: Dictionary Models
# ============================================
func example_dictionary_model():
	var player_data = {
		"name": "Feyr",
		"level": 5,
		"experience": 1250,
		"is_alive": true,
		"gold": 500
	}
	
	var schema = {
		"level": {
			"type": "slider",
			"min": 1,
			"max": 50
		},
		"gold": {
			"readonly": true
		},
		"fields": ["name", "level", "experience", "is_alive"]  # Control field order
	}
	
	var auto_form = AutoFormBuilder.new()
	add_child(auto_form)
	
	auto_form.show_model("player", player_data, schema)
	
	auto_form.edit_confirmed.connect(func(models):
		var player = models["player"]
		print("Player: ", player["name"], " Level: ", player["level"])
	)

# ============================================
# Example 5: Custom Control Types
# ============================================
func example_custom_controls():
	var settings = {
		"volume": 75,
		"brightness": 50,
		"fullscreen": true,
		"quality": "High"
	}
	
	var schema = {
		"volume": {
			"label": "Volume",
			"type": "slider",
			"min": 0,
			"max": 100
		},
		"brightness": {
			"label": "Brightness",
			"type": "slider",
			"min": 0,
			"max": 100
		},
		"fullscreen": {
			"label": "Fullscreen Mode",
			"type": "bool"
		},
		"quality": {
			"label": "Graphics Quality"
		}
	}
	
	var auto_form = AutoFormBuilder.new()
	add_child(auto_form)
	
	auto_form.show_model("settings", settings, schema)

# ============================================
# Schema Options Reference
# ============================================
# Available schema properties:
#
# "label": String - Display label for the field
# "type": String - Control type:
#   - "auto" (default) - Auto-detect from value
#   - "string" - LineEdit
#   - "multiline" - TextEdit
#   - "int" - SpinBox for integers
#   - "float" - SpinBox for floats
#   - "bool" - CheckBox
#   - "slider" - HSlider
#   - "readonly" - Display only
#
# "readonly": bool - If true, field cannot be edited
# "min": float/int - Minimum value (for int/float/slider)
# "max": float/int - Maximum value (for int/float/slider)
# "step": float/int - Step size (for int/float/slider)
# "multiline": bool - Use TextEdit instead of LineEdit for strings
#
# Model-level schema properties:
# "fields": Array[String] - Explicit list of fields to show (controls order)
