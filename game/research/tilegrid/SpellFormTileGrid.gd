class_name SpellFormTileGrid
extends Control

signal cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_unhovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot)
signal tile_placed(grid_pos: Vector2i, slot: SpellFormSlot, tile: SpellFormTile)
signal held_tile_changed(tile: SpellFormTile)

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

# Held tile for click-to-place interaction
var _held_tile: SpellFormTile = null
var _cursor_preview: Control = null
var _hovered_grid_pos: Variant = null  # Vector2i or null

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
	_cells[grid_pos] = cell
	_grid_container.add_child(cell)

func _remove_cell_visual(grid_pos: Vector2i) -> void:
	if not _cells.has(grid_pos):
		return

	var cell = _cells[grid_pos]
	cell.cell_hovered.disconnect(_on_cell_hovered)
	cell.cell_unhovered.disconnect(_on_cell_unhovered)
	cell.cell_clicked.disconnect(_on_cell_clicked)
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
	_hovered_grid_pos = grid_pos
	_update_cursor_preview_tint()
	cell_hovered.emit(grid_pos, slot)

func _on_cell_unhovered(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	_hovered_grid_pos = null
	_update_cursor_preview_tint()
	cell_unhovered.emit(grid_pos, slot)

func _on_cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	# If holding a tile, try to place it
	if _held_tile != null and slot != null:
		if slot.can_accept_tile.call(_held_tile):
			tile_placed.emit(grid_pos, slot, _held_tile)
			# Don't clear held tile - allow multiple placements
			return
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

# Held tile management
func set_held_tile(tile: SpellFormTile) -> void:
	_held_tile = tile
	_update_cursor_preview()
	held_tile_changed.emit(tile)

func get_held_tile() -> SpellFormTile:
	return _held_tile

func clear_held_tile() -> void:
	_held_tile = null
	_destroy_cursor_preview()
	held_tile_changed.emit(null)

func has_held_tile() -> bool:
	return _held_tile != null

func _input(event: InputEvent) -> void:
	# Right-click to clear held tile
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if _held_tile != null:
				clear_held_tile()
				get_viewport().set_input_as_handled()

func _update_cursor_preview() -> void:
	_destroy_cursor_preview()
	if _held_tile == null:
		return

	_cursor_preview = Control.new()
	_cursor_preview.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	_cursor_preview.size = Vector2(CELL_SIZE, CELL_SIZE)
	_cursor_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_preview.z_index = 100  # Draw on top

	var tile_ref = _held_tile
	_cursor_preview.draw.connect(func():
		var rect = Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE))
		tile_ref.draw_tile(_cursor_preview, rect)
	)

	add_child(_cursor_preview)
	_update_cursor_preview_tint()
	set_process(true)

func _destroy_cursor_preview() -> void:
	if _cursor_preview != null:
		_cursor_preview.queue_free()
		_cursor_preview = null
	set_process(false)

func _process(_delta: float) -> void:
	if _cursor_preview == null:
		set_process(false)
		return

	# Scale preview to match camera zoom
	var zoom = _camera.get_zoom()
	_cursor_preview.scale = Vector2(zoom, zoom)

	# Snap to cell if over a valid spot, otherwise follow cursor
	if _hovered_grid_pos != null and _check_held_tile_validity():
		# Snap to cell position
		var cell_world_pos = Vector2(_hovered_grid_pos.x * CELL_SIZE, _hovered_grid_pos.y * CELL_SIZE)
		_cursor_preview.position = _camera._world_to_screen(cell_world_pos)
	else:
		# Follow cursor, offset so cursor is at center (accounting for scaled size)
		var mouse_pos = get_local_mouse_position()
		var scaled_offset = Vector2(CELL_SIZE * zoom / 2.0, CELL_SIZE * zoom / 2.0)
		_cursor_preview.position = mouse_pos - scaled_offset

func _update_cursor_preview_tint() -> void:
	if _cursor_preview == null:
		return

	var is_valid = _check_held_tile_validity()
	if is_valid:
		_cursor_preview.modulate = Color.WHITE
	else:
		_cursor_preview.modulate = Color(1, 0.3, 0.3)  # Red tint

func _check_held_tile_validity() -> bool:
	if _held_tile == null:
		return false

	if _hovered_grid_pos == null:
		return false

	var slot = get_slot(_hovered_grid_pos)
	if slot == null:
		return false

	return slot.can_accept_tile.call(_held_tile)
