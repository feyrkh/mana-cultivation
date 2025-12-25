# FormFieldSchema.gd
# Helper class for defining AutoFormBuilder field schemas with autocomplete
class_name FormFieldSchema
extends RefCounted

# ============================================
# Basic Field Properties
# ============================================

## Display label for the field (defaults to capitalized field name)
var label: String = ""

## Control type to use for this field
## Options: "auto", "string", "text", "multiline", "int", "float", "bool", "slider", "readonly"
var type: String = "auto"

## If true, field cannot be edited (display only)
var readonly: bool = false

# ============================================
# Numeric Field Properties (int, float, slider)
# ============================================

## Minimum value for numeric fields
var min: float = -999999.0

## Maximum value for numeric fields
var max: float = 999999.0

## Step size for numeric fields
var step: float = 1.0

# ============================================
# String Field Properties
# ============================================

## If true, uses TextEdit instead of LineEdit for strings
var multiline: bool = false

# ============================================
# Array Field Properties
# ============================================

## Layout for array items: "vbox" (default) or "hbox"
var array_layout: String = "vbox"

## Schema to apply to each item in the array
var item_schema: FormFieldSchema = null

## If true, shows edit buttons on individual array items
var show_item_buttons: bool = false

# ============================================
# Custom Scene Properties
# ============================================

## Path to a custom .tscn file to use instead of auto-generated controls
## Example: "res://custom_editors/hp_editor.tscn"
var scene: String = ""

# ============================================
# Model-Level Properties (for model schema)
# ============================================

## Explicit list of fields to show (controls order and visibility)
## Example: ["name", "level", "hp"] - only these fields will be shown in this order
var fields: Array[String] = []

# ============================================
# Helper Methods
# ============================================

## Convert this schema to a Dictionary for use with AutoFormBuilder
func to_dict() -> Dictionary:
	var result = {}
	
	if label != "":
		result["label"] = label
	if type != "auto":
		result["type"] = type
	if readonly:
		result["readonly"] = readonly
	if min != -999999.0:
		result["min"] = min
	if max != 999999.0:
		result["max"] = max
	if step != 1.0:
		result["step"] = step
	if multiline:
		result["multiline"] = multiline
	if array_layout != "vbox":
		result["array_layout"] = array_layout
	if not item_schema.is_empty():
		result["item_schema"] = item_schema.to_dict()
	if show_item_buttons:
		result["show_item_buttons"] = show_item_buttons
	if scene != "":
		result["scene"] = scene
	if not fields.is_empty():
		result["fields"] = fields
	
	return result

## Create a schema for a string field
static func string_field(p_label: String = "", p_multiline: bool = false) -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = p_label
	schema.type = "multiline" if p_multiline else "string"
	schema.multiline = p_multiline
	return schema

## Create a schema for an integer field
static func int_field(p_label: String = "", p_min: int = 0, p_max: int = 999, p_step: int = 1) -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = p_label
	schema.type = "int"
	schema.min = p_min
	schema.max = p_max
	schema.step = p_step
	return schema

## Create a schema for a float field
static func float_field(p_label: String = "", p_min: float = 0.0, p_max: float = 999.0, p_step: float = 0.1) -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = p_label
	schema.type = "float"
	schema.min = p_min
	schema.max = p_max
	schema.step = p_step
	return schema

## Create a schema for a slider field
static func slider_field(p_label: String = "", p_min: float = 0, p_max: float = 100, p_step: float = 1) -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = p_label
	schema.type = "slider"
	schema.min = p_min
	schema.max = p_max
	schema.step = p_step
	return schema

## Create a schema for a boolean field
static func bool_field(p_label: String = "") -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = p_label
	schema.type = "bool"
	return schema

## Create a schema for a readonly field
static func readonly_field(p_label: String = "") -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = p_label
	schema.readonly = true
	return schema

## Create a schema for an array field
static func array_field(p_label: String = "", p_layout: String = "vbox", p_item_schema: FormFieldSchema = null) -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = p_label
	schema.array_layout = p_layout
	schema.item_schema = p_item_schema
	return schema

## Create a schema for a custom scene field
static func custom_scene_field(p_scene_path: String, p_label: String = "") -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = p_label
	schema.scene = p_scene_path
	return schema


# ============================================
# CUSTOM SCENE LIFECYCLE METHODS REFERENCE
# ============================================
# When using a custom scene (scene property), your scene can implement these methods:
#
# func before_add_to_form(model, value, schema: Dictionary, field_name: String):
#     # Called BEFORE the scene is added to the form tree
#     # Use this to initialize your scene with the current value
#     # 
#     # Parameters:
#     #   model       - The parent model object/dictionary
#     #   value       - The current value of this field
#     #   schema      - The schema dictionary for this field
#     #   field_name  - The name of the field being edited
#     #
#     # Example:
#     #   current_value = value
#     #   max_value = schema.get("max", 100)
#
# func after_add_to_form(model, value, schema: Dictionary, field_name: String):
#     # Called AFTER the scene has been added to the form tree
#     # Use this for setup that requires the scene to be in the tree
#     # (connecting signals, accessing parent nodes, etc.)
#     #
#     # Parameters: Same as before_add_to_form
#     #
#     # Example:
#     #   slider.value_changed.connect(_on_value_changed)
#     #   label.text = str(value)
#
# func on_mode_changed(is_edit_mode: bool):
#     # Called when the form switches between view and edit mode
#     # Use this to show/hide your edit controls
#     #
#     # Parameters:
#     #   is_edit_mode - true if entering edit mode, false for view mode
#     #
#     # Example:
#     #   view_label.visible = not is_edit_mode
#     #   edit_container.visible = is_edit_mode
#
# func before_save(model, field_name: String):
#     # Called BEFORE saving changes to the model
#     # Use this to validate data or perform pre-save operations
#     #
#     # Parameters:
#     #   model       - The parent model object/dictionary
#     #   field_name  - The name of the field being saved
#     #
#     # Example:
#     #   if not is_valid():
#     #       push_error("Invalid value!")
#
# func get_field_value():
#     # Called to retrieve the edited value from your scene
#     # REQUIRED if your field is editable
#     # Must return the new value to be saved to the model
#     #
#     # Returns: The edited value (any type)
#     #
#     # Example:
#     #   return current_value
#
# func after_save(model, field_name: String):
#     # Called AFTER changes have been saved to the model
#     # Use this for cleanup, notifications, or triggering other updates
#     #
#     # Parameters: Same as before_save
#     #
#     # Example:
#     #   print("Saved successfully!")
#     #   update_display()
#
# func before_cancel():
#     # Called BEFORE canceling changes (reverting to original values)
#     # Use this to reset your scene's state or clean up
#     #
#     # Example:
#     #   reset_to_original_value()
#     #   clear_validation_errors()


# ============================================
# Usage Examples
# ============================================

## Example 1: Simple field schemas
static func example_simple_schemas() -> Dictionary:
	return {
		"name": FormFieldSchema.string_field("Character Name").to_dict(),
		"hp": FormFieldSchema.int_field("Health Points", 0, 999).to_dict(),
		"speed": FormFieldSchema.slider_field("Speed", 0, 100).to_dict(),
		"is_alive": FormFieldSchema.bool_field("Alive").to_dict(),
		"id": FormFieldSchema.readonly_field("ID").to_dict()
	}

## Example 2: Array with item schema
static func example_array_schema() -> Dictionary:
	var item_schema = {
		"id": FormFieldSchema.readonly_field().to_dict(),
		"display_name": FormFieldSchema.string_field("Effect Name").to_dict(),
		"duration": FormFieldSchema.int_field("Duration", 1, 10).to_dict()
	}
	
	return {
		"status_effects": FormFieldSchema.array_field(
			"Status Effects",
			"vbox",
			item_schema
		).to_dict()
	}

## Example 3: Custom scene
static func example_custom_scene() -> Dictionary:
	return {
		"hp": FormFieldSchema.custom_scene_field(
			"res://custom_editors/hp_editor.tscn",
			"Health Points"
		).to_dict()
	}

## Example 4: Complete character schema
static func example_character_schema() -> Dictionary:
	# Define item schema for status effects array
	var status_effect_schema = {
		"id": FormFieldSchema.readonly_field("ID").to_dict(),
		"display_name": FormFieldSchema.string_field("Effect").to_dict()
	}
	
	return {
		"name": FormFieldSchema.string_field("Name").to_dict(),
		"hp": FormFieldSchema.int_field("HP", 0, 999).to_dict(),
		"status_effects": FormFieldSchema.array_field(
			"Status Effects",
			"vbox",
			status_effect_schema
		).to_dict()
	}

## Example 5: Manual schema building with all options
static func example_manual_schema() -> FormFieldSchema:
	var schema = FormFieldSchema.new()
	schema.label = "Experience Points"
	schema.type = "slider"
	schema.min = 0
	schema.max = 10000
	schema.step = 100
	schema.readonly = false
	return schema

## Example 6: Using FormFieldSchema in code
static func example_usage():
	var auto_form = AutoFormBuilder.new()
	
	var hero = Character.new("Feyr", 100, [])
	
	# Build schema using helper methods
	var schema = {
		"name": FormFieldSchema.string_field("Character Name").to_dict(),
		"hp": FormFieldSchema.slider_field("Health", 0, 200).to_dict(),
		"status_effects": FormFieldSchema.readonly_field("Effects").to_dict()
	}
	
	auto_form.show_model("hero", hero, schema)
