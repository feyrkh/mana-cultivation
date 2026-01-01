class_name SpellFormTileGrid
extends Control

signal cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_unhovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot)
signal tile_dropped(grid_pos: Vector2i, slot: SpellFormSlot, tile: SpellFormTile)

const CELL_SIZE := SpellFormGridCell.CELL_SIZE
const BOUNDS_PADDING := 400.0

# The SpellForm being displayed (cloned from input)
var _spellform: SpellForm = null

# Visual cells
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

# Set the SpellForm to display (creates a deep clone)
func set_spellform(spellform: SpellForm) -> void:
	_clear_cells()
	_spellform = spellform.clone()
	_rebuild_cells()

# Get the internal SpellForm (the cloned copy)
func get_spellform() -> SpellForm:
	return _spellform

# Add a cell/slot at the given grid position
func add_cell(grid_pos: Vector2i, tile: SpellFormTile = null) -> bool:
	if _spellform == null:
		_spellform = SpellForm.new()

	var slot = _spellform.add_slot(grid_pos)
	if slot == null:
		return false

	if tile != null:
		slot.spell_form_tile = tile

	_create_cell_visual(grid_pos)
	_update_bounds()
	return true

# Remove a cell/slot at the given grid position
func remove_cell(grid_pos: Vector2i) -> void:
	if _spellform == null:
		return

	_spellform.remove_slot(grid_pos)
	_remove_cell_visual(grid_pos)
	_update_bounds()

# Get the slot at a grid position
func get_slot(grid_pos: Vector2i) -> SpellFormSlot:
	if _spellform == null:
		return null
	return _spellform.get_slot(grid_pos)

# Check if a cell exists at a grid position
func has_cell(grid_pos: Vector2i) -> bool:
	if _spellform == null:
		return false
	return _spellform.has_slot(grid_pos)

# Set the tile for a cell (creates the cell if it doesn't exist)
func set_tile(grid_pos: Vector2i, tile: SpellFormTile) -> bool:
	if _spellform == null:
		_spellform = SpellForm.new()

	var result = _spellform.place_tile(grid_pos, tile)
	if result:
		if not _cells.has(grid_pos):
			_create_cell_visual(grid_pos)
		else:
			_update_cell_visual(grid_pos)
		_update_bounds()
	return result

# Clear the tile from a cell (keeps the cell as empty)
func clear_tile(grid_pos: Vector2i) -> SpellFormTile:
	if _spellform == null:
		return null

	var tile = _spellform.remove_tile(grid_pos)
	_update_cell_visual(grid_pos)
	return tile

# Get all grid positions that have cells
func get_cell_positions() -> Array[Vector2i]:
	if _spellform == null:
		return []
	return _spellform.get_all_positions()

# Get all occupied positions (cells with tiles)
func get_occupied_positions() -> Array[Vector2i]:
	if _spellform == null:
		return []
	return _spellform.get_occupied_positions()

# Clear all cells
func clear_all() -> void:
	_clear_cells()
	_spellform = null
	_update_bounds()

func _clear_cells() -> void:
	for pos in _cells.keys():
		_remove_cell_visual(pos)
	_cells.clear()

func _rebuild_cells() -> void:
	_clear_cells()
	if _spellform == null:
		return

	for pos in _spellform.grid.keys():
		_create_cell_visual(pos)

	_update_bounds()

func _create_cell_visual(grid_pos: Vector2i) -> void:
	if _cells.has(grid_pos):
		return

	var slot = _spellform.get_slot(grid_pos) if _spellform else null

	var cell = SpellFormGridCell.new()
	cell.set_grid_position(grid_pos)
	cell.set_slot(slot)
	cell.cell_hovered.connect(_on_cell_hovered)
	cell.cell_unhovered.connect(_on_cell_unhovered)
	cell.cell_clicked.connect(_on_cell_clicked)
	cell.tile_dropped.connect(_on_tile_dropped)
	_cells[grid_pos] = cell
	_grid_container.add_child(cell)

func _remove_cell_visual(grid_pos: Vector2i) -> void:
	if not _cells.has(grid_pos):
		return

	var cell = _cells[grid_pos]
	cell.cell_hovered.disconnect(_on_cell_hovered)
	cell.cell_unhovered.disconnect(_on_cell_unhovered)
	cell.cell_clicked.disconnect(_on_cell_clicked)
	cell.tile_dropped.disconnect(_on_tile_dropped)
	cell.queue_free()
	_cells.erase(grid_pos)

func _update_cell_visual(grid_pos: Vector2i) -> void:
	if not _cells.has(grid_pos):
		return

	var slot = _spellform.get_slot(grid_pos) if _spellform else null
	_cells[grid_pos].set_slot(slot)

func _update_bounds() -> void:
	if _spellform == null or _spellform.grid.is_empty():
		_has_cells = false
		_min_bounds = Vector2i.ZERO
		_max_bounds = Vector2i.ZERO
		_camera.set_bounds(Rect2(-BOUNDS_PADDING, -BOUNDS_PADDING, BOUNDS_PADDING * 2, BOUNDS_PADDING * 2))
		return

	_has_cells = true
	var first = true

	for pos: Vector2i in _spellform.grid.keys():
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

func _on_tile_dropped(grid_pos: Vector2i, slot: SpellFormSlot, tile: SpellFormTile) -> void:
	tile_dropped.emit(grid_pos, slot, tile)

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
