class_name TileToolbar
extends PanelContainer

const ITEM_SPACING := 4

var _flow_container: HFlowContainer
var _items: Array[TileToolbarItem] = []
var _target_grid: SpellFormTileGrid = null

func _init() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Create flow container for wrapping layout
	_flow_container = HFlowContainer.new()
	_flow_container.name = "FlowContainer"
	_flow_container.add_theme_constant_override("h_separation", ITEM_SPACING)
	_flow_container.add_theme_constant_override("v_separation", ITEM_SPACING)
	add_child(_flow_container)

func set_tiles(tiles: Array[SpellFormTile]) -> void:
	clear()
	for tile in tiles:
		add_tile(tile)

func add_tile(tile: SpellFormTile) -> TileToolbarItem:
	var item = TileToolbarItem.new(tile)
	if _target_grid:
		item.set_target_grid(_target_grid)
	_items.append(item)
	_flow_container.add_child(item)
	return item

func remove_tile(tile: SpellFormTile) -> void:
	for i in range(_items.size() - 1, -1, -1):
		if _items[i].tile == tile:
			var item = _items[i]
			_items.remove_at(i)
			item.queue_free()
			break

func clear() -> void:
	for item in _items:
		item.queue_free()
	_items.clear()

func set_target_grid(grid: SpellFormTileGrid) -> void:
	_target_grid = grid
	for item in _items:
		item.set_target_grid(grid)

func get_items() -> Array[TileToolbarItem]:
	return _items
