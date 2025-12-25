# CharacterRenderer.gd
# Example implementation of ModelRenderer for Character display/editing
class_name CharacterRenderer
extends ModelRenderer

# Define the mapping between model paths and UI node names
func get_render_mapping() -> Dictionary:
	return {
		"char1.name": "CharacterName",
		"char1.hp": "Health",
		"char1.status_effects": "StatusEffects"
	}

func _ready():
	# Connect signals if needed
	edit_confirmed.connect(_on_edit_confirmed)
	edit_cancelled.connect(_on_edit_cancelled)
	setup_demo()

func _on_edit_confirmed(updated_models: Dictionary):
	print("Changes confirmed!")
	for key in updated_models:
		var model = updated_models[key]
		if model is Character:
			print("Character: " + model.name + ", HP: " + str(model.hp))

func _on_edit_cancelled():
	print("Changes cancelled!")

# ============================================
# Example usage scene setup
# ============================================

# Example scene tree structure:
# CharacterRenderer (CharacterRenderer.gd)
#   └─ Container (VBoxContainer)
#       ├─ NameContainer (HBoxContainer)
#       │   ├─ CharacterNameView (Label)
#       │   └─ CharacterNameEdit (LineEdit)
#       ├─ HealthContainer (HBoxContainer)
#       │   ├─ HealthView (Label)
#       │   └─ HealthEdit (SpinBox)
#       ├─ StatusEffectsView (Label)
#       └─ ButtonContainer (HBoxContainer)
#           ├─ EditButton (Button)
#           ├─ ConfirmButton (Button)
#           └─ CancelButton (Button)

# ============================================
# Complete example with scene setup
# ============================================

func setup_demo():
	# Create the renderer
	var character_renderer = self
	
	# Build UI programmatically (in real usage, you'd use a scene)
	var container = VBoxContainer.new()
	character_renderer.add_child(container)
	
	# Name field
	var name_container = HBoxContainer.new()
	container.add_child(name_container)
	
	var name_label = Label.new()
	name_label.name = "CharacterNameView"
	name_label.text = "Hero"
	name_container.add_child(name_label)
	
	var name_edit = LineEdit.new()
	name_edit.name = "CharacterNameEdit"
	name_edit.visible = false
	name_container.add_child(name_edit)
	
	# Health field
	var health_container = HBoxContainer.new()
	container.add_child(health_container)
	
	var health_label = Label.new()
	health_label.name = "HealthView"
	health_label.text = "100"
	health_container.add_child(health_label)
	
	var health_spin = SpinBox.new()
	health_spin.name = "HealthEdit"
	health_spin.min_value = 0
	health_spin.max_value = 999
	health_spin.visible = false
	health_container.add_child(health_spin)
	
	# Status effects (view only, no edit)
	var status_label = Label.new()
	status_label.name = "StatusEffectsView"
	status_label.text = "[]"
	container.add_child(status_label)
	
	# Buttons
	var button_container = HBoxContainer.new()
	container.add_child(button_container)
	
	var edit_button = Button.new()
	edit_button.text = "Edit"
	edit_button.pressed.connect(_on_edit_pressed)
	button_container.add_child(edit_button)
	
	var confirm_button = Button.new()
	confirm_button.text = "Confirm"
	confirm_button.pressed.connect(_on_confirm_pressed)
	button_container.add_child(confirm_button)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_on_cancel_pressed)
	button_container.add_child(cancel_button)
	
	# Create test data
	var poison = StatusEffect.new(1, "Poison", {"damage": 5})
	var bless = StatusEffect.new(1, "Blessed", {"holiness": 1})
	var hero = Character.new("Feyr", 100, [poison, bless])
	
	# Show in view mode initially
	show_models({"char1": hero}, false)
	
	# Mark status_effects as uneditable
	set_uneditable_fields(["char1.status_effects"])
	
func _on_edit_pressed():
	# Get current models and switch to edit mode
	show_models(models, true)

func _on_confirm_pressed():
	confirm_edit()

func _on_cancel_pressed():
	cancel_edit()


# ============================================
# Advanced example: Custom field renderer
# ============================================

# Example of rendering nested stats dictionary
class AdvancedCharacterRenderer extends ModelRenderer:
	func get_render_mapping() -> Dictionary:
		return {
			"player.name": "PlayerName",
			"player.stats.hp": "HP",
			"player.stats.mp": "MP",
			"player.stats.attack": "Attack",
			"player.inventory.gold": "Gold"
		}
	
	# Override to handle custom rendering for complex types
	func _set_node_value(node: Node, value) -> void:
		# Custom handling for status effects array
		if value is Array and node.name.contains("StatusEffects"):
			var effects_text = ""
			for effect in value:
				if effect is StatusEffect:
					effects_text += effect.display_name + ", "
			if effects_text.length() > 0:
				effects_text = effects_text.substr(0, effects_text.length() - 2)
			node.text = effects_text
		else:
			# Fall back to default behavior
			super._set_node_value(node, value)

# ============================================
# Usage with nested data
# ============================================

func example_nested_data():
	var renderer = AdvancedCharacterRenderer.new()
	
	var player_data = {
		"name": "Feyr",
		"stats": {
			"hp": 100,
			"mp": 50,
			"attack": 25
		},
		"inventory": {
			"gold": 500,
			"items": []
		}
	}
	
	renderer.show_models({"player": player_data}, false)
	
	# Later, switch to edit mode
	renderer.show_models(renderer.models, true)
	
	# Make certain fields readonly
	renderer.set_uneditable_fields(["player.inventory.gold"])
