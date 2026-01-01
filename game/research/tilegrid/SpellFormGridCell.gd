class_name SpellFormGridCell
extends Control

signal cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_unhovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot)
signal tile_dropped(grid_pos: Vector2i, slot: SpellFormSlot, tile: SpellFormTile)

enum CellState { MISSING, EMPTY, OCCUPIED }

const CELL_SIZE := 64.0
const OUTLINE_WIDTH := 2.0

var grid_position: Vector2i = Vector2i.ZERO
var slot: SpellFormSlot = null
var cell_state: CellState = CellState.MISSING

var _is_hovered: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, Vector2(CELL_SIZE, CELL_SIZE))

	match cell_state:
		CellState.MISSING:
			# Blank - draw nothing
			pass
		CellState.EMPTY:
			# Gray outline only
			var outline_color = Color(0.5, 0.5, 0.5)
			_draw_outline(rect, outline_color)
		CellState.OCCUPIED:
			# Let the tile draw itself
			if slot and slot.spell_form_tile:
				slot.spell_form_tile.draw_tile(self, rect)

func _draw_outline(rect: Rect2, color: Color) -> void:
	# Top
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, OUTLINE_WIDTH)), color)
	# Bottom
	draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - OUTLINE_WIDTH), Vector2(rect.size.x, OUTLINE_WIDTH)), color)
	# Left
	draw_rect(Rect2(rect.position, Vector2(OUTLINE_WIDTH, rect.size.y)), color)
	# Right
	draw_rect(Rect2(Vector2(rect.end.x - OUTLINE_WIDTH, rect.position.y), Vector2(OUTLINE_WIDTH, rect.size.y)), color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cell_clicked.emit(grid_position, slot)
			accept_event()

func _on_mouse_entered() -> void:
	_is_hovered = true
	cell_hovered.emit(grid_position, slot)

func _on_mouse_exited() -> void:
	_is_hovered = false
	cell_unhovered.emit(grid_position, slot)

func set_slot(p_slot: SpellFormSlot) -> void:
	slot = p_slot
	if slot == null:
		cell_state = CellState.MISSING
	elif slot.spell_form_tile == null:
		cell_state = CellState.EMPTY
	else:
		cell_state = CellState.OCCUPIED
	queue_redraw()

func set_empty() -> void:
	slot = SpellFormSlot.new()
	cell_state = CellState.EMPTY
	queue_redraw()

func set_missing() -> void:
	slot = null
	cell_state = CellState.MISSING
	queue_redraw()

func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos
	position = Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Only accept SpellFormTile drops
	if not data is SpellFormTile:
		return false

	# Must have a slot (cell must exist)
	if slot == null:
		return false

	# Check if slot accepts this tile
	return slot.can_accept_tile.call(data)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is SpellFormTile:
		return

	if slot == null:
		return

	tile_dropped.emit(grid_position, slot, data as SpellFormTile)
