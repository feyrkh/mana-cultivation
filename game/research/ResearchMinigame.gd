extends Control
class_name ResearchMinigame

func _ready() -> void:
	var tiles:Array[SpellFormTile] = [
		ResourceMgr.load_clone(SpellFormTile, "ponder"),
		ResourceMgr.load_clone(SpellFormTile, "optical_refraction"),
	]
	%SpellFormTileGrid.add_cell(Vector2i(0, 0))
	setup(%SpellFormTileGrid, tiles)
	%SpellFormTileGrid.cell_hovered.connect(_on_cell_hovered)
	%SpellFormTileGrid.cell_unhovered.connect(_on_cell_unhovered)
	%SpellFormTileGrid.cell_clicked.connect(_on_cell_clicked)
	%SpellFormTileGrid.tile_placed.connect(_on_tile_placed)


func setup(grid:SpellFormTileGrid, tiles:Array[SpellFormTile]):
	%TileToolbar.set_target_grid(grid)
	%TileToolbar.set_tiles(tiles)

func _on_cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	if slot and slot.spell_form_tile:
		%HeaderLabel.text = "Hover: (%d, %d) - %s" % [grid_pos.x, grid_pos.y, slot.spell_form_tile.id]
	elif slot:
		%HeaderLabel.text = "Hover: (%d, %d) - Empty" % [grid_pos.x, grid_pos.y]
	else:
		%HeaderLabel.text = "Hover: (%d, %d) - Missing" % [grid_pos.x, grid_pos.y]

func _on_cell_unhovered(_grid_pos: Vector2i, _slot: SpellFormSlot) -> void:
	%HeaderLabel.text = ""

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
	%SpellFormTileGrid.set_tile(grid_pos, tile)
