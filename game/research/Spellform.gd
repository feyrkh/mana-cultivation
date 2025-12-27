class_name SpellForm
extends RefCounted

enum SlotState {
	EMPTY,      # Slot exists but has no tile
	OCCUPIED,   # Slot contains a SpellFormTile
	BLOCKED     # Slot cannot be used
}

# Grid structure: Dictionary with Vector2i keys mapping to slot data
# Each slot stores: { "state": SlotState, "tile": SpellFormTile or null }
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
func get_tile(pos: Vector2i) -> SpellFormTile:
	if not is_valid_position(pos):
		return null
	return grid[pos]["tile"]

# Place a tile at position
func place_tile(pos: Vector2i, tile: SpellFormTile) -> bool:
	if not is_valid_position(pos):
		return false
	if grid[pos]["state"] == SlotState.BLOCKED:
		return false
	
	grid[pos]["state"] = SlotState.OCCUPIED
	grid[pos]["tile"] = tile
	return true

# Remove tile at position
func remove_tile(pos: Vector2i) -> SpellFormTile:
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
