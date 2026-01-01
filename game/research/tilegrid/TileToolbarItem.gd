class_name TileToolbarItem
extends Control

const ITEM_SIZE := 64.0

var tile: SpellFormTile
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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if tile != null and _target_grid != null:
				_target_grid.set_held_tile(tile)
				accept_event()

func set_target_grid(grid: SpellFormTileGrid) -> void:
	_target_grid = grid
