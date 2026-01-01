# AdjacencyEffect.gd
class_name AdjacencyEffect
extends Resource

# --- Core, strongly-typed fields (mechanics) ---
@export var effect_type: String        # "resource_delta", "volatility", etc.
@export var resource: String           # Name of the resource affected
@export var amount: float = 0.0        # Magnitude of the effect
@export var target_tag: String = ""    # Which neighboring tile tag this applies to
@export var conditions: Dictionary = {} # e.g., {"min_integration": 1}

# --- Optional, unstructured metadata for designers ---
@export var extras: Dictionary = {}    # Any arbitrary data (notes, animations, tooltips, formulas)

# --- Helper method for evaluating if this effect applies ---
func matches(source_tile: SpellFormTile, target_tile: SpellFormTile) -> bool:
	# Check tag
	if target_tag != "" and target_tile.tag != target_tag:
		return false
	
	# Check conditions
	if conditions.has("min_integration") and source_tile.integration < conditions.min_integration:
		return false
	
	# Add any custom checks in extras["custom_predicate"] if needed
	if extras.has("custom_predicate") and typeof(extras["custom_predicate"]) == TYPE_CALLABLE:
		if not extras["custom_predicate"].call(source_tile, target_tile):
			return false
	
	return true
