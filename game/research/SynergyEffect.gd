class_name SynergyEffect
extends Resource

# --- Core fields ---
@export var pattern: Array[String] = []       # Neighbor tags or IDs required
@export var unlock_at_integration: int = 1    # Min integration to activate

@export var effect_type: String = "resource_delta"   # "resource_delta", "volatility", "cohesion"
@export var resource: String = ""                     # Resource affected
@export var amount: float = 0.0                      # Base amount

# --- Optional fields ---
@export var extras: Dictionary = {}                 # Notes, scaling curves, or designer metadata

# --- Helper: check if synergy is active given placed tile and neighbors ---
func is_active(placed_tile: SpellFormTile, neighbor_tiles: Array[SpellFormTile]) -> bool:
	if placed_tile.integration < unlock_at_integration:
		return false
	
	for required_tag in pattern:
		var found := false
		for neighbor in neighbor_tiles:
			if neighbor.tag == required_tag:
				found = true
				break
		if not found:
			return false
	
	return true
