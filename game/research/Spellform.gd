class_name SpellForm
extends RefCounted

enum SlotState {
	EMPTY,      # Slot exists but has no tile
	OCCUPIED,   # Slot contains a SpellFormTile
	BLOCKED     # Slot cannot be used
}

# Sparse grid: Dictionary with Vector2i keys mapping to SpellFormSlot objects
# Missing keys = no slot at that position
var grid: Dictionary = {}  # Dictionary[Vector2i, SpellFormSlot]

# Optional fixed bounds (null = unbounded/sparse)
var fixed_bounds: Rect2i = Rect2i()
var use_fixed_bounds: bool = false

func _init(p_grid_size: Vector2i = Vector2i.ZERO) -> void:
	if p_grid_size != Vector2i.ZERO:
		use_fixed_bounds = true
		fixed_bounds = Rect2i(Vector2i.ZERO, p_grid_size)
		_initialize_fixed_grid()

# Initialize a fixed-size grid with empty slots
func _initialize_fixed_grid() -> void:
	grid.clear()
	for y in range(fixed_bounds.size.y):
		for x in range(fixed_bounds.size.x):
			var pos = Vector2i(x, y) + fixed_bounds.position
			var slot = SpellFormSlot.new()
			grid[pos] = slot

# Check if a position has a slot
func has_slot(pos: Vector2i) -> bool:
	return grid.has(pos)

# Check if a position is valid (for fixed bounds mode)
func is_valid_position(pos: Vector2i) -> bool:
	if use_fixed_bounds:
		return fixed_bounds.has_point(pos)
	return true  # Unbounded mode allows any position

# Get slot at position (returns null if no slot exists)
func get_slot(pos: Vector2i) -> SpellFormSlot:
	return grid.get(pos, null)

# Get slot state at position
func get_slot_state(pos: Vector2i) -> SlotState:
	var slot = get_slot(pos)
	if slot == null:
		return SlotState.BLOCKED  # No slot = blocked
	if slot.spell_form_tile != null:
		return SlotState.OCCUPIED
	return SlotState.EMPTY

# Get tile at position (returns null if empty or no slot)
func get_tile(pos: Vector2i) -> SpellFormTile:
	var slot = get_slot(pos)
	if slot == null:
		return null
	return slot.spell_form_tile

# Add an empty slot at position (for sparse grids)
func add_slot(pos: Vector2i) -> SpellFormSlot:
	if use_fixed_bounds and not fixed_bounds.has_point(pos):
		return null
	if grid.has(pos):
		return grid[pos]
	var slot = SpellFormSlot.new()
	grid[pos] = slot
	return slot

# Remove a slot at position (for sparse grids)
func remove_slot(pos: Vector2i) -> void:
	grid.erase(pos)

# Place a tile at position (creates slot if needed in unbounded mode)
func place_tile(pos: Vector2i, tile: SpellFormTile) -> bool:
	var slot = get_slot(pos)
	if slot == null:
		if use_fixed_bounds:
			return false
		slot = add_slot(pos)
	slot.spell_form_tile = tile
	return true

# Remove tile at position (keeps slot as empty)
func remove_tile(pos: Vector2i) -> SpellFormTile:
	var slot = get_slot(pos)
	if slot == null:
		return null
	var tile = slot.spell_form_tile
	slot.spell_form_tile = null
	return tile

# Block a slot (removes it in sparse mode, or marks empty in fixed mode)
func block_slot(pos: Vector2i) -> bool:
	if use_fixed_bounds:
		# In fixed mode, just clear the tile
		var slot = get_slot(pos)
		if slot:
			slot.spell_form_tile = null
		return slot != null
	else:
		# In sparse mode, remove the slot entirely
		remove_slot(pos)
		return true

# Unblock a slot (add empty slot)
func unblock_slot(pos: Vector2i) -> bool:
	return add_slot(pos) != null

# Get all positions that have slots
func get_all_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for pos in grid.keys():
		positions.append(pos)
	return positions

# Get all occupied positions (slots with tiles)
func get_occupied_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for pos in grid.keys():
		var slot: SpellFormSlot = grid[pos]
		if slot.spell_form_tile != null:
			positions.append(pos)
	return positions

# Get orthogonal neighbors of a position (only those with slots)
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
		if has_slot(neighbor_pos):
			neighbors.append(neighbor_pos)

	return neighbors

# Create a deep clone of this SpellForm
func clone() -> SpellForm:
	var copy = SpellForm.new()
	copy.use_fixed_bounds = use_fixed_bounds
	copy.fixed_bounds = fixed_bounds

	for pos in grid.keys():
		var original_slot: SpellFormSlot = grid[pos]
		var new_slot = SpellFormSlot.new()
		new_slot.spell_form_tile = original_slot.spell_form_tile  # Tiles are shared (not cloned)
		new_slot.inertia = original_slot.inertia
		new_slot.integration = original_slot.integration
		# adjacent_tiles will be recalculated as needed
		copy.grid[pos] = new_slot

	return copy

# Legacy compatibility: grid_size property
var grid_size: Vector2i:
	get:
		if use_fixed_bounds:
			return fixed_bounds.size
		# For sparse grids, calculate bounding box
		if grid.is_empty():
			return Vector2i.ZERO
		var min_pos = Vector2i(999999, 999999)
		var max_pos = Vector2i(-999999, -999999)
		for pos in grid.keys():
			min_pos.x = min(min_pos.x, pos.x)
			min_pos.y = min(min_pos.y, pos.y)
			max_pos.x = max(max_pos.x, pos.x)
			max_pos.y = max(max_pos.y, pos.y)
		return max_pos - min_pos + Vector2i.ONE
