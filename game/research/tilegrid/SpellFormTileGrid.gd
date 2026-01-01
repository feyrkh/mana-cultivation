class_name SpellFormTileGrid
extends Control

signal cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_unhovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot)

const CELL_SIZE := SpellFormGridCell.CELL_SIZE
const BOUNDS_PADDING := 400.0

# Sparse grid: Vector2i -> SpellFormSlot (null slot = empty cell, missing key = no cell)
var _grid: Dictionary = {}  # Dictionary[Vector2i, SpellFormSlot]
var _cells: Dictionary = {}  # Dictionary[Vector2i, SpellFormGridCell]

var _camera: DraggableCamera2D
var _grid_container: Control

# Track grid bounds for camera
var _min_bounds: Vector2i = Vector2i.ZERO
var _max_bounds: Vector2i = Vector2i.ZERO
var _has_cells: bool = false

func _ready() -> void:
	_setup_camera()
	_update_bounds()

func _setup_camera() -> void:
	_camera = DraggableCamera2D.new()
	_camera.name = "Camera"
	_camera.set_anchors_preset(Control.PRESET_FULL_RECT)
	_camera.enable_bounds = true
	add_child(_camera)

	_grid_container = Control.new()
	_grid_container.name = "GridContainer"
	_camera.add_content(_grid_container)

# Add a cell at the given grid position
# If slot is null, creates an empty cell; if slot has a tile, creates an occupied cell
func add_cell(grid_pos: Vector2i, slot: SpellFormSlot = null) -> SpellFormGridCell:
	# Remove existing cell if present
	if _cells.has(grid_pos):
		remove_cell(grid_pos)

	# Create the slot if not provided
	if slot == null:
		slot = SpellFormSlot.new()

	_grid[grid_pos] = slot

	# Create visual cell
	var cell = SpellFormGridCell.new()
	cell.set_grid_position(grid_pos)
	cell.set_slot(slot)
	cell.cell_hovered.connect(_on_cell_hovered)
	cell.cell_unhovered.connect(_on_cell_unhovered)
	cell.cell_clicked.connect(_on_cell_clicked)
	_cells[grid_pos] = cell
	_grid_container.add_child(cell)

	_update_bounds()
	return cell

# Remove a cell at the given grid position
func remove_cell(grid_pos: Vector2i) -> void:
	if not _cells.has(grid_pos):
		return

	var cell = _cells[grid_pos]
	cell.cell_hovered.disconnect(_on_cell_hovered)
	cell.cell_unhovered.disconnect(_on_cell_unhovered)
	cell.cell_clicked.disconnect(_on_cell_clicked)
	cell.queue_free()

	_cells.erase(grid_pos)
	_grid.erase(grid_pos)

	_update_bounds()

# Get the slot at a grid position (returns null if no cell exists)
func get_slot(grid_pos: Vector2i) -> SpellFormSlot:
	return _grid.get(grid_pos, null)

# Check if a cell exists at a grid position
func has_cell(grid_pos: Vector2i) -> bool:
	return _grid.has(grid_pos)

# Set the tile for a cell (creates the cell if it doesn't exist)
func set_tile(grid_pos: Vector2i, tile: SpellFormTile) -> void:
	var slot: SpellFormSlot
	if _grid.has(grid_pos):
		slot = _grid[grid_pos]
	else:
		slot = SpellFormSlot.new()
		add_cell(grid_pos, slot)

	slot.spell_form_tile = tile

	if _cells.has(grid_pos):
		_cells[grid_pos].set_slot(slot)

# Clear the tile from a cell (keeps the cell as empty)
func clear_tile(grid_pos: Vector2i) -> void:
	if not _grid.has(grid_pos):
		return

	var slot = _grid[grid_pos]
	slot.spell_form_tile = null

	if _cells.has(grid_pos):
		_cells[grid_pos].set_slot(slot)

# Get all grid positions that have cells
func get_cell_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for pos in _grid.keys():
		positions.append(pos)
	return positions

# Get all occupied positions (cells with tiles)
func get_occupied_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for pos in _grid.keys():
		var slot = _grid[pos]
		if slot and slot.spell_form_tile != null:
			positions.append(pos)
	return positions

# Clear all cells
func clear_all() -> void:
	for pos in _cells.keys().duplicate():
		remove_cell(pos)
	_update_bounds()

# Load from a SpellForm object
func load_from_spellform(spellform: SpellForm) -> void:
	clear_all()

	for pos in spellform.grid.keys():
		var grid_data = spellform.grid[pos]
		var state = grid_data["state"]
		var tile = grid_data["tile"]

		# Skip blocked slots - they become missing in our grid
		if state == SpellForm.SlotState.BLOCKED:
			continue

		var slot = SpellFormSlot.new()
		slot.spell_form_tile = tile
		add_cell(pos, slot)

func _update_bounds() -> void:
	if _grid.is_empty():
		_has_cells = false
		_min_bounds = Vector2i.ZERO
		_max_bounds = Vector2i.ZERO
		_camera.set_bounds(Rect2(-BOUNDS_PADDING, -BOUNDS_PADDING, BOUNDS_PADDING * 2, BOUNDS_PADDING * 2))
		return

	_has_cells = true
	var first = true

	for pos: Vector2i in _grid.keys():
		if first:
			_min_bounds = pos
			_max_bounds = pos
			first = false
		else:
			_min_bounds.x = min(_min_bounds.x, pos.x)
			_min_bounds.y = min(_min_bounds.y, pos.y)
			_max_bounds.x = max(_max_bounds.x, pos.x)
			_max_bounds.y = max(_max_bounds.y, pos.y)

	# Calculate world bounds (add 1 to max because cells have size)
	var world_min = Vector2(_min_bounds.x * CELL_SIZE, _min_bounds.y * CELL_SIZE) - Vector2(BOUNDS_PADDING, BOUNDS_PADDING)
	var world_max = Vector2((_max_bounds.x + 1) * CELL_SIZE, (_max_bounds.y + 1) * CELL_SIZE) + Vector2(BOUNDS_PADDING, BOUNDS_PADDING)

	var bounds_rect = Rect2(world_min, world_max - world_min)
	_camera.set_bounds(bounds_rect)

func _on_cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	cell_hovered.emit(grid_pos, slot)

func _on_cell_unhovered(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	cell_unhovered.emit(grid_pos, slot)

func _on_cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	cell_clicked.emit(grid_pos, slot)

# Camera access
func get_camera() -> DraggableCamera2D:
	return _camera

func center_on_grid() -> void:
	if not _has_cells:
		_camera.set_camera_position(Vector2.ZERO)
		return

	var center_x = (_min_bounds.x + _max_bounds.x + 1) * CELL_SIZE / 2.0
	var center_y = (_min_bounds.y + _max_bounds.y + 1) * CELL_SIZE / 2.0
	_camera.set_camera_position(Vector2(center_x, center_y))
