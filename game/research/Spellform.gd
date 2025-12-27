class_name Spellform
extends RefCounted

static func _static_init() -> void:
	LoadSystem.register_class("Spellform", Spellform)

enum SlotState {
	EMPTY,      # Slot exists but has no tile
	OCCUPIED,   # Slot contains a SpellformTile
	BLOCKED     # Slot cannot be used
}

# Grid structure: Dictionary with Vector2i keys mapping to slot data
# Each slot stores: { "state": SlotState, "tile": SpellformTile or null }
var grid: Dictionary = {}
var grid_size: Vector2i = Vector2i(3, 3)  # Default 3x3 grid

func _init(p_grid_size: Vector2i = Vector2i(3, 3)) -> void:
	grid_size = p_grid_size
	_initialize_grid()

# Initialize empty grid
func _initialize_grid() -> void:
	grid.clear()
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			grid[pos] = {
				"state": SlotState.EMPTY,
				"tile": null
			}

# Check if a position is valid on the grid
func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

# Get slot state at position
func get_slot_state(pos: Vector2i) -> SlotState:
	if not is_valid_position(pos):
		return SlotState.BLOCKED
	return grid[pos]["state"]

# Get tile at position (returns null if empty or blocked)
func get_tile(pos: Vector2i) -> SpellformTile:
	if not is_valid_position(pos):
		return null
	return grid[pos]["tile"]

# Place a tile at position
func place_tile(pos: Vector2i, tile: SpellformTile) -> bool:
	if not is_valid_position(pos):
		return false
	if grid[pos]["state"] == SlotState.BLOCKED:
		return false
	
	grid[pos]["state"] = SlotState.OCCUPIED
	grid[pos]["tile"] = tile
	return true

# Remove tile at position
func remove_tile(pos: Vector2i) -> SpellformTile:
	if not is_valid_position(pos):
		return null
	
	var tile = grid[pos]["tile"]
	grid[pos]["state"] = SlotState.EMPTY
	grid[pos]["tile"] = null
	return tile

# Block a slot
func block_slot(pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		return false
	
	grid[pos]["state"] = SlotState.BLOCKED
	grid[pos]["tile"] = null
	return true

# Unblock a slot (set to empty)
func unblock_slot(pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		return false
	
	grid[pos]["state"] = SlotState.EMPTY
	grid[pos]["tile"] = null
	return true

# Get all occupied positions
func get_occupied_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for pos in grid.keys():
		if grid[pos]["state"] == SlotState.OCCUPIED:
			positions.append(pos)
	return positions

# Get orthogonal neighbors of a position
func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]
	
	for dir in directions:
		var neighbor_pos = pos + dir
		if is_valid_position(neighbor_pos):
			neighbors.append(neighbor_pos)
	
	return neighbors

# Serialize to dictionary
func to_dict() -> Dictionary:
	# Serialize grid as array of slot data
	var grid_data: Array = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			var slot = grid[pos]
			var slot_data = {
				"x": x,
				"y": y,
				"state": slot["state"]
			}
			
			# Serialize tile if present
			if slot["tile"] != null:
				slot_data["tile"] = slot["tile"].to_dict()
			
			grid_data.append(slot_data)
	
	var result = {
		"__class__": "Spellform",
		"grid_size_x": grid_size.x,
		"grid_size_y": grid_size.y,
		"grid_data": grid_data
	}
	return result

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> Spellform:
	var spellform = Spellform.new()
	# Load grid size
	var size_x = dict.get("grid_size_x", 3)
	var size_y = dict.get("grid_size_y", 3)
	spellform.grid_size = Vector2i(size_x, size_y)
	spellform._initialize_grid()
	
	# Load grid data
	var grid_data: Array = dict.get("grid_data", [])
	for slot_data in grid_data:
		if not slot_data is Dictionary:
			continue
		
		var x = slot_data.get("x", 0)
		var y = slot_data.get("y", 0)
		var pos = Vector2i(x, y)
		
		if not spellform.is_valid_position(pos):
			continue
		
		var state = slot_data.get("state", SlotState.EMPTY)
		spellform.grid[pos]["state"] = state
		
		# Deserialize tile if present
		if slot_data.has("tile"):
			var tile_dict = slot_data["tile"]
			if tile_dict is Dictionary:
				spellform.grid[pos]["tile"] = SpellformTile.from_dict(tile_dict)
	return spellform
