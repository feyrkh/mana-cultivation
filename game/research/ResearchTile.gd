# ResearchTile.gd
class_name ResearchTile
extends RefCounted

enum TileTag {
	CONSENSUS,
	TENUOUS,
	CRACKPOT
}

# Tile identity
var tile_name: String
var tag: TileTag

# Mechanical properties
var base_effect: Dictionary = {}  # {"type": "damage", "value": 10}, etc.
var base_volatility: int = 1  # 1-3

# Integration state
var integration_level: int = 0

# Position on board (null if in hand/deck)
var board_position: Vector2i = Vector2i(-1, -1)

func _init(
	p_name: String = "",
	p_tag: TileTag = TileTag.CONSENSUS,
	p_base_effect: Dictionary = {},
	p_base_volatility: int = 1
) -> void:
	tile_name = p_name
	tag = p_tag
	base_effect = p_base_effect.duplicate(true)
	base_volatility = clampi(p_base_volatility, 1, 3)
	integration_level = 0

# Get maximum integration level based on tag
func get_max_integration_level() -> int:
	match tag:
		TileTag.CONSENSUS:
			return 3
		TileTag.TENUOUS:
			return 2
		TileTag.CRACKPOT:
			return 1
	return 1

# Get current effect value (scaled by integration)
func get_current_effect() -> Dictionary:
	var max_level = get_max_integration_level()
	if max_level == 0:
		return base_effect.duplicate(true)
	
	var scale_factor = float(integration_level) / float(max_level)
	var scaled_effect = base_effect.duplicate(true)
	
	# Scale numeric values
	for key in scaled_effect.keys():
		if scaled_effect[key] is int or scaled_effect[key] is float:
			scaled_effect[key] = base_effect[key] * scale_factor
	
	return scaled_effect

# Get current volatility (decreases with integration)
func get_current_volatility() -> float:
	var max_level = get_max_integration_level()
	if max_level == 0:
		return base_volatility
	
	var scale_factor = 1.0 - (float(integration_level) / float(max_level))
	return base_volatility * scale_factor

# Check if tile can be integrated further
func can_integrate() -> bool:
	return integration_level < get_max_integration_level()

# Integrate the tile by one level
func integrate() -> bool:
	if not can_integrate():
		return false
	
	integration_level += 1
	return true

# Get cohesion change when integrating this tile
func get_integration_cohesion_change() -> int:
	match tag:
		TileTag.CONSENSUS:
			return 1
		TileTag.TENUOUS:
			return 0
		TileTag.CRACKPOT:
			return -1
	return 0

# Check if tile is placed on board
func is_placed() -> bool:
	return board_position.x >= 0 and board_position.y >= 0

# Get adjacency effect bonus
func get_adjacency_bonus() -> float:
	match tag:
		TileTag.CONSENSUS:
			return 0.10  # +10%
		TileTag.TENUOUS:
			return 0.0   # no bonus
		TileTag.CRACKPOT:
			return 0.20  # +20%
	return 0.0

# Lifecycle hooks for save/load
func pre_save() -> void:
	pass

func post_save() -> void:
	pass

func pre_load() -> void:
	pass

func post_load() -> void:
	pass

# Serialize to dictionary
func to_dict() -> Dictionary:
	pre_save()
	var result = {
		"__class__": "ResearchTile",
		"tile_name": tile_name,
		"tag": tag,
		"base_effect": base_effect.duplicate(true),
		"base_volatility": base_volatility,
		"integration_level": integration_level,
		"board_position": {"x": board_position.x, "y": board_position.y}
	}
	post_save()
	return result

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> ResearchTile:
	var tile = ResearchTile.new()
	tile.pre_load()
	
	tile.tile_name = dict.get("tile_name", "")
	tile.tag = dict.get("tag", TileTag.CONSENSUS)
	tile.base_effect = dict.get("base_effect", {}).duplicate(true)
	tile.base_volatility = dict.get("base_volatility", 1)
	tile.integration_level = dict.get("integration_level", 0)
	
	var pos_dict = dict.get("board_position", {"x": -1, "y": -1})
	tile.board_position = Vector2i(pos_dict.get("x", -1), pos_dict.get("y", -1))
	
	tile.post_load()
	return tile
