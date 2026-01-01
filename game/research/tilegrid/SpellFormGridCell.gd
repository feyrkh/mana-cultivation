class_name SpellFormGridCell
extends Control

signal cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_unhovered(grid_pos: Vector2i, slot: SpellFormSlot)
signal cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot)

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
			# White fill with gray outline
			var fill_color = Color.WHITE
			var outline_color = Color(0.5, 0.5, 0.5)
			draw_rect(rect.grow(-OUTLINE_WIDTH), fill_color)
			_draw_outline(rect, outline_color)

			# Draw tile ID text
			if slot and slot.spell_form_tile:
				var tile_id = slot.spell_form_tile.id
				_draw_centered_text(tile_id, rect, Color.BLACK)

func _draw_outline(rect: Rect2, color: Color) -> void:
	# Top
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, OUTLINE_WIDTH)), color)
	# Bottom
	draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - OUTLINE_WIDTH), Vector2(rect.size.x, OUTLINE_WIDTH)), color)
	# Left
	draw_rect(Rect2(rect.position, Vector2(OUTLINE_WIDTH, rect.size.y)), color)
	# Right
	draw_rect(Rect2(Vector2(rect.end.x - OUTLINE_WIDTH, rect.position.y), Vector2(OUTLINE_WIDTH, rect.size.y)), color)

func _draw_centered_text(text: String, rect: Rect2, color: Color) -> void:
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = rect.position + (rect.size - text_size) / 2.0
	text_pos.y += text_size.y * 0.75  # Adjust for baseline
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

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
