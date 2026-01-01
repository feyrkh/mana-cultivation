class_name TileToolbarItem
extends Control

const ITEM_SIZE := 64.0

var tile: SpellFormTile
var _is_dragging: bool = false
var _drag_preview: Control = null
var _target_grid: SpellFormTileGrid = null

func _init(p_tile: SpellFormTile = null) -> void:
	tile = p_tile
	custom_minimum_size = Vector2(ITEM_SIZE, ITEM_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, Vector2(ITEM_SIZE, ITEM_SIZE))
	if tile:
		tile.draw_tile(self, rect)
	else:
		# Fallback: just draw an empty white square with outline
		draw_rect(rect, Color.WHITE)
		var outline_width := 1.0
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, outline_width)), Color.BLACK)
		draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - outline_width), Vector2(rect.size.x, outline_width)), Color.BLACK)
		draw_rect(Rect2(rect.position, Vector2(outline_width, rect.size.y)), Color.BLACK)
		draw_rect(Rect2(Vector2(rect.end.x - outline_width, rect.position.y), Vector2(outline_width, rect.size.y)), Color.BLACK)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if tile == null:
		return null

	_is_dragging = true

	# Create drag preview
	_drag_preview = _create_preview()
	set_drag_preview(_drag_preview)

	# Start monitoring for tinting
	set_process(true)

	return tile

func _create_preview() -> Control:
	var preview = Control.new()
	preview.custom_minimum_size = Vector2(ITEM_SIZE, ITEM_SIZE)
	preview.size = Vector2(ITEM_SIZE, ITEM_SIZE)

	# Draw the preview using the tile's rendering method
	var tile_ref = tile
	preview.draw.connect(func():
		var rect = Rect2(Vector2.ZERO, Vector2(ITEM_SIZE, ITEM_SIZE))
		if tile_ref:
			tile_ref.draw_tile(preview, rect)
	)

	return preview

func _process(_delta: float) -> void:
	if not _is_dragging:
		set_process(false)
		return

	_update_preview_tint()

func _update_preview_tint() -> void:
	var preview = _drag_preview
	if preview == null or !is_instance_valid(preview):
		return

	var is_valid_drop = _check_drop_validity()

	if is_valid_drop:
		preview.modulate = Color.WHITE
	else:
		preview.modulate = Color(1, 0.3, 0.3)  # Red tint

func _check_drop_validity() -> bool:
	if _target_grid == null:
		# Try to find a grid under the cursor
		_target_grid = _find_grid_under_cursor()

	if _target_grid == null:
		return false

	var mouse_pos = get_global_mouse_position()
	var grid_pos = _get_grid_position_at(mouse_pos)

	if grid_pos == null:
		return false

	var slot = _target_grid.get_slot(grid_pos)
	if slot == null:
		return false  # No cell exists at this position

	# Check if slot accepts this tile
	return slot.can_accept_tile.call(tile)

func _find_grid_under_cursor() -> SpellFormTileGrid:
	var mouse_pos = get_global_mouse_position()

	# Walk up the tree to find grids
	var node = get_tree().root
	return _find_grid_recursive(node, mouse_pos)

func _find_grid_recursive(node: Node, mouse_pos: Vector2) -> SpellFormTileGrid:
	if node is SpellFormTileGrid:
		var grid = node as SpellFormTileGrid
		var rect = grid.get_global_rect()
		if rect.has_point(mouse_pos):
			return grid

	for child in node.get_children():
		var result = _find_grid_recursive(child, mouse_pos)
		if result:
			return result

	return null

func _get_grid_position_at(global_pos: Vector2) -> Variant:
	if _target_grid == null:
		return null

	var camera = _target_grid.get_camera()
	if camera == null:
		return null

	# Convert global position to camera-local position
	var local_pos = global_pos - camera.global_position

	# Convert to world position using camera transform
	var world_pos = camera._screen_to_world(local_pos)

	# Convert world position to grid position
	var cell_size = SpellFormGridCell.CELL_SIZE
	var grid_x = int(floor(world_pos.x / cell_size))
	var grid_y = int(floor(world_pos.y / cell_size))

	return Vector2i(grid_x, grid_y)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_is_dragging = false
		_drag_preview = null
		set_process(false)

func set_target_grid(grid: SpellFormTileGrid) -> void:
	_target_grid = grid
