# ResearchBoard.gd
class_name ResearchBoard
extends RefCounted

const BOARD_SIZE: Vector2i = Vector2i(3, 3)

# Board state - 2D array of tiles (null = empty)
var tiles: Array = []  # Array of Array of ResearchTile

func _init() -> void:
	_initialize_board()

func _initialize_board() -> void:
	tiles.clear()
	for y in range(BOARD_SIZE.y):
		var row: Array = []
		for x in range(BOARD_SIZE.x):
			row.append(null)
		tiles.append(row)

# Check if position is valid
func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE.x and pos.y >= 0 and pos.y < BOARD_SIZE.y

# Check if position is empty
func is_empty(pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		return false
	return tiles[pos.y][pos.x] == null

# Get tile at position
func get_tile(pos: Vector2i) -> ResearchTile:
	if not is_valid_position(pos):
		return null
	return tiles[pos.y][pos.x]

# Place tile at position
func place_tile(tile: ResearchTile, pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		push_error("Invalid board position: " + str(pos))
		return false
	
	if not is_empty(pos):
		push_error("Position already occupied: " + str(pos))
		return false
	
	tiles[pos.y][pos.x] = tile
	tile.board_position = pos
	return true

# Remove tile from position
func remove_tile(pos: Vector2i) -> ResearchTile:
	if not is_valid_position(pos):
		return null
	
	var tile = tiles[pos.y][pos.x]
	if tile != null:
		tile.board_position = Vector2i(-1, -1)
		tiles[pos.y][pos.x] = null
	
	return tile

# Get orthogonal neighbors (up, down, left, right)
func get_adjacent_positions(pos: Vector2i) -> Array[Vector2i]:
	var adjacents: Array[Vector2i] = []
	var offsets = [
		Vector2i(0, -1),  # up
		Vector2i(0, 1),   # down
		Vector2i(-1, 0),  # left
		Vector2i(1, 0)    # right
	]
	
	for offset in offsets:
		var neighbor_pos = pos + offset
		if is_valid_position(neighbor_pos):
			adjacents.append(neighbor_pos)
	
	return adjacents

# Get adjacent tiles (non-null)
func get_adjacent_tiles(pos: Vector2i) -> Array[ResearchTile]:
	var adjacent_tiles: Array[ResearchTile] = []
	var adjacent_positions = get_adjacent_positions(pos)
	
	for adj_pos in adjacent_positions:
		var tile = get_tile(adj_pos)
		if tile != null:
			adjacent_tiles.append(tile)
	
	return adjacent_tiles

# Calculate adjacency pressure for a specific tile
func calculate_tile_adjacency_pressure(pos: Vector2i) -> int:
	var tile = get_tile(pos)
	if tile == null:
		return 0
	
	var total_pressure: int = 0
	var adjacent_tiles = get_adjacent_tiles(pos)
	
	for adj_tile in adjacent_tiles:
		var pressure = _get_adjacency_pressure(tile, adj_tile)
		total_pressure += pressure
	
	return total_pressure

# Get adjacency pressure between two tiles
func _get_adjacency_pressure(tile1: ResearchTile, tile2: ResearchTile) -> int:
	var base_pressure: int = 0
	
	# Determine base pressure from table
	if tile1.tag == ResearchTile.TileTag.CONSENSUS and tile2.tag == ResearchTile.TileTag.CONSENSUS:
		base_pressure = 1
	elif (tile1.tag == ResearchTile.TileTag.CONSENSUS and tile2.tag == ResearchTile.TileTag.TENUOUS) or \
	     (tile1.tag == ResearchTile.TileTag.TENUOUS and tile2.tag == ResearchTile.TileTag.CONSENSUS):
		base_pressure = 0
	elif tile1.tag == ResearchTile.TileTag.TENUOUS and tile2.tag == ResearchTile.TileTag.TENUOUS:
		base_pressure = 0
	elif (tile1.tag == ResearchTile.TileTag.CONSENSUS and tile2.tag == ResearchTile.TileTag.CRACKPOT) or \
	     (tile1.tag == ResearchTile.TileTag.CRACKPOT and tile2.tag == ResearchTile.TileTag.CONSENSUS):
		base_pressure = -1
	elif (tile1.tag == ResearchTile.TileTag.TENUOUS and tile2.tag == ResearchTile.TileTag.CRACKPOT) or \
	     (tile1.tag == ResearchTile.TileTag.CRACKPOT and tile2.tag == ResearchTile.TileTag.TENUOUS):
		base_pressure = -1
	elif tile1.tag == ResearchTile.TileTag.CRACKPOT and tile2.tag == ResearchTile.TileTag.CRACKPOT:
		base_pressure = -2
	
	# Apply integration reduction for penalties
	if base_pressure < 0:
		# If both tiles are integrated, apply 50% penalty (minimum -1)
		if tile1.integration_level > 0 and tile2.integration_level > 0:
			var reduced = int(floor(float(base_pressure) * 0.5))
			# Ensure minimum -1 if there was any penalty
			return max(reduced, -1)
	
	return base_pressure

# Calculate total adjacency pressure for entire board
func calculate_total_adjacency_pressure() -> int:
	var total_pressure: int = 0
	var processed_pairs: Dictionary = {}  # Track processed pairs to avoid double-counting
	
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			var pos = Vector2i(x, y)
			var tile = get_tile(pos)
			if tile == null:
				continue
			
			var adjacent_positions = get_adjacent_positions(pos)
			for adj_pos in adjacent_positions:
				var adj_tile = get_tile(adj_pos)
				if adj_tile == null:
					continue
				
				# Create unique pair key to avoid double-counting
				var pair_key = _get_pair_key(pos, adj_pos)
				if not processed_pairs.has(pair_key):
					var pressure = _get_adjacency_pressure(tile, adj_tile)
					total_pressure += pressure
					processed_pairs[pair_key] = true
	
	return total_pressure

# Create unique key for tile pair
func _get_pair_key(pos1: Vector2i, pos2: Vector2i) -> String:
	var min_pos = pos1 if (pos1.x < pos2.x or (pos1.x == pos2.x and pos1.y < pos2.y)) else pos2
	var max_pos = pos2 if min_pos == pos1 else pos1
	return str(min_pos) + "_" + str(max_pos)

# Get all placed tiles
func get_all_tiles() -> Array[ResearchTile]:
	var all_tiles: Array[ResearchTile] = []
	
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			var tile = tiles[y][x]
			if tile != null:
				all_tiles.append(tile)
	
	return all_tiles

# Count tiles by integration status
func count_integrated_tiles() -> int:
	var count: int = 0
	for tile in get_all_tiles():
		if tile.integration_level > 0:
			count += 1
	return count

# Count total adjacency links
func count_adjacency_links() -> int:
	var link_count: int = 0
	var processed_pairs: Dictionary = {}
	
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			var pos = Vector2i(x, y)
			var tile = get_tile(pos)
			if tile == null:
				continue
			
			var adjacent_positions = get_adjacent_positions(pos)
			for adj_pos in adjacent_positions:
				var adj_tile = get_tile(adj_pos)
				if adj_tile == null:
					continue
				
				var pair_key = _get_pair_key(pos, adj_pos)
				if not processed_pairs.has(pair_key):
					link_count += 1
					processed_pairs[pair_key] = true
	
	return link_count

# Clear board
func clear() -> void:
	_initialize_board()

# Serialize to dictionary
func to_dict() -> Dictionary:
	var tiles_data: Array = []
	
	for y in range(BOARD_SIZE.y):
		var row_data: Array = []
		for x in range(BOARD_SIZE.x):
			var tile = tiles[y][x]
			if tile != null:
				row_data.append(tile.to_dict())
			else:
				row_data.append(null)
		tiles_data.append(row_data)
	
	return {
		"__class__": "ResearchBoard",
		"board_size": {"x": BOARD_SIZE.x, "y": BOARD_SIZE.y},
		"tiles": tiles_data
	}

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> ResearchBoard:
	var board = ResearchBoard.new()
	
	var tiles_data = dict.get("tiles", [])
	for y in range(min(tiles_data.size(), BOARD_SIZE.y)):
		var row_data = tiles_data[y]
		for x in range(min(row_data.size(), BOARD_SIZE.x)):
			var tile_dict = row_data[x]
			if tile_dict != null and tile_dict is Dictionary:
				var tile = ResearchTile.from_dict(tile_dict)
				board.tiles[y][x] = tile
	
	return board
