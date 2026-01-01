extends Control

@onready var tile_grid: SpellFormTileGrid = $SpellFormTileGrid
@onready var info_label: Label = $InfoLabel

func _ready() -> void:
	# Connect signals
	tile_grid.cell_hovered.connect(_on_cell_hovered)
	tile_grid.cell_unhovered.connect(_on_cell_unhovered)
	tile_grid.cell_clicked.connect(_on_cell_clicked)

	# Create a test SpellForm and load it
	var spellform = _create_test_spellform()
	tile_grid.set_spellform(spellform)

	# Center the camera on the grid
	tile_grid.center_on_grid()

func _create_test_spellform() -> SpellForm:
	# Create an unbounded SpellForm (no fixed size)
	var spellform = SpellForm.new()

	# Add some test slots
	var test_positions = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		# Some outliers to test sparse grid
		Vector2i(-2, -1),
		Vector2i(5, 3),
	]

	for pos in test_positions:
		spellform.add_slot(pos)

		# Make some cells occupied with tiles
		if pos.x == pos.y or pos == Vector2i(2, 1):
			var tile = SpellFormTile.new()
			tile.id = "tile_%d_%d" % [pos.x, pos.y]
			spellform.place_tile(pos, tile)

	return spellform

func _on_cell_hovered(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	if slot and slot.spell_form_tile:
		info_label.text = "Hover: (%d, %d) - %s" % [grid_pos.x, grid_pos.y, slot.spell_form_tile.id]
	elif slot:
		info_label.text = "Hover: (%d, %d) - Empty" % [grid_pos.x, grid_pos.y]
	else:
		info_label.text = "Hover: (%d, %d) - Missing" % [grid_pos.x, grid_pos.y]

func _on_cell_unhovered(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	info_label.text = ""

func _on_cell_clicked(grid_pos: Vector2i, slot: SpellFormSlot) -> void:
	if slot and slot.spell_form_tile:
		info_label.text = "Clicked: (%d, %d) - %s" % [grid_pos.x, grid_pos.y, slot.spell_form_tile.id]
	elif slot:
		info_label.text = "Clicked: (%d, %d) - Empty" % [grid_pos.x, grid_pos.y]
	else:
		info_label.text = "Clicked: (%d, %d)" % [grid_pos.x, grid_pos.y]

func _input(event: InputEvent) -> void:
	# Press A to add a random cell
	if event is InputEventKey and event.pressed and event.keycode == KEY_A:
		var rand_pos = Vector2i(randi_range(-5, 10), randi_range(-5, 10))
		var tile: SpellFormTile = null
		if randf() > 0.5:
			tile = SpellFormTile.new()
			tile.id = "new_%d" % randi_range(0, 999)
		tile_grid.add_cell(rand_pos, tile)
		info_label.text = "Added cell at (%d, %d)" % [rand_pos.x, rand_pos.y]

	# Press R to remove a random cell
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		var positions = tile_grid.get_cell_positions()
		if not positions.is_empty():
			var pos = positions[randi() % positions.size()]
			tile_grid.remove_cell(pos)
			info_label.text = "Removed cell at (%d, %d)" % [pos.x, pos.y]
