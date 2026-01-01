extends Control
class_name ResearchMinigame

var cur_selected_tile:SpellFormTile

func _ready() -> void:
	var tiles:Array[SpellFormTile] = [
		ResourceMgr.load_clone(SpellFormTile, "ponder"),
		ResourceMgr.load_clone(SpellFormTile, "optical_refraction"),
	]
	%TileGrid.add_cell(Vector2i(0, 0))
	setup(%TileGrid, tiles)
	%TileGrid.cell_hovered.connect(_on_cell_hovered)
	%TileGrid.cell_unhovered.connect(_on_cell_unhovered)
	%TileGrid.cell_clicked.connect(_on_cell_clicked)
	%TileGrid.tile_placed.connect(_on_tile_placed)
	%TileGrid.held_tile_changed.connect(_on_toolbar_item_changed)
	%TileToolbar.item_hovered.connect(_on_toolbar_item_hovered)
	%TileToolbar.item_unhovered.connect(_on_toolbar_item_unhovered)
	%TileToolbar.item_clicked.connect(_on_toolbar_item_clicked)


func setup(grid:SpellFormTileGrid, tiles:Array[SpellFormTile]):
	%TileToolbar.set_target_grid(grid)
	%TileToolbar.set_tiles(tiles)

func _on_toolbar_item_changed(selected_item:SpellFormTile):
	cur_selected_tile = selected_item
	if cur_selected_tile:
		%HeaderLabel.text = "Placing: %s" % [selected_item.label]
	else:
		%HeaderLabel.text = ''

func _on_toolbar_item_hovered(selected_item:TileToolbarItem):
	%HeaderLabel.text = selected_item.tile.label

func _on_toolbar_item_unhovered(selected_item:TileToolbarItem):
	_on_toolbar_item_changed(cur_selected_tile)

func _on_toolbar_item_clicked(selected_item:TileToolbarItem):
	pass

func _on_cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	if slot and slot.spell_form_tile and cur_selected_tile:
		%HeaderLabel.text = "Will replace %s with %s" % [slot.spell_form_tile.label, cur_selected_tile.label]
	elif slot and slot.spell_form_tile and not cur_selected_tile:
		%HeaderLabel.text = "Current tile: %s" % [slot.spell_form_tile.label]
	elif slot and cur_selected_tile:
		%HeaderLabel.text = "Will place %s" % [cur_selected_tile.label]
	elif slot:
		%HeaderLabel.text = "Empty"
	else:
		%HeaderLabel.text = "" % [grid_pos.x, grid_pos.y]

func _on_cell_unhovered(_grid_pos: Vector2i, _slot: SpellFormSlot) -> void:
	_on_toolbar_item_changed(cur_selected_tile)

func _on_cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	if slot and slot.spell_form_tile:
		%HeaderLabel.text = "Clicked: (%d, %d) - %s" % [grid_pos.x, grid_pos.y, slot.spell_form_tile.id]
	elif slot:
		%HeaderLabel.text = "Clicked: (%d, %d) - Empty" % [grid_pos.x, grid_pos.y]
	else:
		%HeaderLabel.text = "Clicked: (%d, %d)" % [grid_pos.x, grid_pos.y]

func _on_tile_placed(grid_pos: Vector2i, _slot: SpellFormSlot, tile: SpellFormTile) -> void:
	%HeaderLabel.text = "Placed: %s at (%d, %d)" % [tile.id, grid_pos.x, grid_pos.y]
	# Actually place the tile
	%TileGrid.set_tile(grid_pos, tile)
