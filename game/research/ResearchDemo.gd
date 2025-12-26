# ResearchDemo.gd
# Demonstration of the Magical Research Minigame system
extends Node

func _ready():
	demo_complete_research_session()

func demo_complete_research_session():
	print("=== MAGICAL RESEARCH MINIGAME DEMO ===\n")
	
	# 1. Create a spell intent
	print("1. Creating Spell Intent...")
	var intent = SpellIntent.new(
		SpellIntent.SpellDomain.LIGHT,
		["low_intensity", "non_combat"],
		["illumination", "warmth"]
	)
	print(intent.get_description())
	print()
	
	# 2. Start a research session
	print("2. Starting Research Session...")
	var session = ResearchSession.new(intent)
	session.start_session()
	
	# Connect signals for logging
	session.weather_changed.connect(_on_weather_changed)
	session.resource_changed.connect(_on_resource_changed)
	session.cohesion_changed.connect(_on_cohesion_changed)
	session.action_performed.connect(_on_action_performed)
	session.turn_advanced.connect(_on_turn_advanced)
	session.session_ended.connect(_on_session_ended)
	
	print("Session started!")
	print("Focus: %d, Insight: %d, Cohesion: %d" % [session.focus, session.insight, session.cohesion])
	print()
	
	# 3. Perform some actions
	print("3. Performing Actions...\n")
	
	# Draw tiles
	print("--- Turn 1: Drawing tiles ---")
	var draw_result = session.action_examine_source()
	if draw_result.success:
		print("Drew tiles:")
		for tile in draw_result.tiles_drawn:
			print("  - %s (%s, volatility: %.1f)" % [
				tile.tile_name,
				_get_tag_name(tile.tag),
				tile.get_current_volatility()
			])
	
	session.advance_turn()
	print()
	
	# Place a tile
	if draw_result.success and not draw_result.tiles_drawn.is_empty():
		print("--- Turn 2: Placing tile ---")
		var tile_to_place = draw_result.tiles_drawn[0]
		var place_result = session.action_place_tile(tile_to_place, Vector2i(1, 1))
		print("Placement result: %s" % place_result.message)
		
		session.advance_turn()
		print()
	
	# Stabilize theory
	print("--- Turn 3: Stabilizing theory ---")
	var stabilize_result = session.action_stabilize_theory()
	print("Stabilization result: %s" % stabilize_result.message)
	
	session.advance_turn()
	print()
	
	# Draw more tiles
	print("--- Turn 4: Drawing more tiles ---")
	draw_result = session.action_examine_source()
	if draw_result.success:
		print("Drew %d tile(s)" % draw_result.tiles_drawn.size())
	
	session.advance_turn()
	print()
	
	# Place another tile
	if draw_result.success and not draw_result.tiles_drawn.is_empty():
		print("--- Turn 5: Placing another tile ---")
		var tile_to_place = draw_result.tiles_drawn[0]
		var place_result = session.action_place_tile(tile_to_place, Vector2i(1, 2))
		print("Placement result: %s" % place_result.message)
		
		session.advance_turn()
		print()
	
	# Integrate a tile
	print("--- Turn 6: Integrating tile ---")
	var integrate_result = session.action_integrate_tile(Vector2i(1, 1))
	print("Integration result: %s" % integrate_result.message)
	if integrate_result.success:
		print("Insight cost: %d" % integrate_result.insight_cost)
	
	session.advance_turn()
	print()
	
	# Try speculative leap
	print("--- Turn 7: Speculative leap ---")
	var leap_result = session.action_speculative_leap()
	print("Leap result: %s" % leap_result.message)
	if leap_result.success and leap_result.tile_generated:
		var tile = leap_result.tile_generated
		print("Generated: %s (volatility: %.1f)" % [tile.tile_name, tile.get_current_volatility()])
	
	session.advance_turn()
	print()
	
	# Check board state
	print("4. Board State Analysis...")
	print_board_state(session)
	print()
	
	# Check completion requirements
	print("5. Checking Completion Requirements...")
	var completion_check = session.action_complete_spell()
	print("Can complete: %s" % str(completion_check.requirements_met))
	if not completion_check.requirements_met:
		print("Missing requirements:")
		for req in completion_check.check_result.missing_requirements:
			print("  - %s" % req)
	print()
	
	# 6. Save session
	print("6. Saving Session...")
	var session_data = [session]
	SaveSystem.save_game(session_data, "research_save_1", "session.dat")
	print("Session saved!")
	print()
	
	# 7. Load session
	print("7. Loading Session...")
	var loaded_sessions = LoadSystem.load_game("research_save_1", "session.dat")
	if not loaded_sessions.is_empty() and loaded_sessions[0] is ResearchSession:
		var loaded_session = loaded_sessions[0]
		print("Session loaded successfully!")
		print("Focus: %d, Insight: %d, Cohesion: %d" % [
			loaded_session.focus,
			loaded_session.insight,
			loaded_session.cohesion
		])
		print_board_state(loaded_session)
	print()

func print_board_state(session: ResearchSession):
	var board = session.board
	var all_tiles = board.get_all_tiles()
	
	print("Board Statistics:")
	print("  Total tiles: %d" % all_tiles.size())
	print("  Integrated tiles: %d" % board.count_integrated_tiles())
	print("  Adjacency links: %d" % board.count_adjacency_links())
	print("  Total adjacency pressure: %d" % board.calculate_total_adjacency_pressure())
	
	if not all_tiles.is_empty():
		print("\nPlaced Tiles:")
		for tile in all_tiles:
			var adjacent_tiles = board.get_adjacent_tiles(tile.board_position)
			print("  %s at %s:" % [tile.tile_name, str(tile.board_position)])
			print("    Tag: %s, Integration: %d/%d" % [
				_get_tag_name(tile.tag),
				tile.integration_level,
				tile.get_max_integration_level()
			])
			print("    Volatility: %.1f, Adjacent: %d tiles" % [
				tile.get_current_volatility(),
				adjacent_tiles.size()
			])

func _get_tag_name(tag: ResearchTile.TileTag) -> String:
	match tag:
		ResearchTile.TileTag.CONSENSUS: return "Consensus"
		ResearchTile.TileTag.TENUOUS: return "Tenuous"
		ResearchTile.TileTag.CRACKPOT: return "Crackpot"
	return "Unknown"

# Signal handlers for logging
func _on_weather_changed(weather: ResearchWeather):
	print("[WEATHER] %s" % weather.get_description())

func _on_resource_changed(resource_name: String, new_value: int):
	print("[RESOURCE] %s: %d" % [resource_name, new_value])

func _on_cohesion_changed(new_value: int):
	print("[COHESION] %d" % new_value)

func _on_action_performed(action_name: String, result: Dictionary):
	pass  # Already logged in the main demo

func _on_turn_advanced(turn_number: int):
	print("[TURN] Turn %d completed" % turn_number)

func _on_session_ended(reason: String, success: bool):
	print("[SESSION END] %s (Success: %s)" % [reason, str(success)])


# ============================================
# Example: Custom tile creation
# ============================================

func example_create_custom_tiles():
	print("\n=== CUSTOM TILE CREATION ===\n")
	
	# Create a consensus tile
	var consensus_tile = ResearchTile.new(
		"Fundamental Light Theory",
		ResearchTile.TileTag.CONSENSUS,
		{"type": "damage", "value": 10},
		1
	)
	print("Created: %s" % consensus_tile.tile_name)
	print("  Max integration: %d" % consensus_tile.get_max_integration_level())
	print("  Base volatility: %d" % consensus_tile.base_volatility)
	print("  Adjacency bonus: %.0f%%" % (consensus_tile.get_adjacency_bonus() * 100))
	print()
	
	# Create a crackpot tile
	var crackpot_tile = ResearchTile.new(
		"Reality Distortion Field",
		ResearchTile.TileTag.CRACKPOT,
		{"type": "damage", "value": 50},
		3
	)
	print("Created: %s" % crackpot_tile.tile_name)
	print("  Max integration: %d" % crackpot_tile.get_max_integration_level())
	print("  Base volatility: %d" % crackpot_tile.base_volatility)
	print("  Adjacency bonus: %.0f%%" % (crackpot_tile.get_adjacency_bonus() * 100))
	print()
	
	# Demonstrate integration effect scaling
	print("Integration scaling for consensus tile:")
	for i in range(consensus_tile.get_max_integration_level() + 1):
		consensus_tile.integration_level = i
		var effect = consensus_tile.get_current_effect()
		var volatility = consensus_tile.get_current_volatility()
		print("  Level %d: Effect value: %.1f, Volatility: %.1f" % [
			i,
			effect.get("value", 0),
			volatility
		])


# ============================================
# Example: Adjacency testing
# ============================================

func example_adjacency_mechanics():
	print("\n=== ADJACENCY MECHANICS ===\n")
	
	var board = ResearchBoard.new()
	
	# Create and place tiles
	var consensus1 = ResearchTile.new("Theory A", ResearchTile.TileTag.CONSENSUS, {}, 1)
	var consensus2 = ResearchTile.new("Theory B", ResearchTile.TileTag.CONSENSUS, {}, 1)
	var crackpot1 = ResearchTile.new("Wild Idea", ResearchTile.TileTag.CRACKPOT, {}, 3)
	
	board.place_tile(consensus1, Vector2i(1, 1))
	board.place_tile(consensus2, Vector2i(2, 1))
	board.place_tile(crackpot1, Vector2i(1, 2))
	
	print("Placed 3 tiles:")
	print("  Consensus at (1,1)")
	print("  Consensus at (2,1)")
	print("  Crackpot at (1,2)")
	print()
	
	# Calculate pressures
	print("Adjacency pressures:")
	print("  Consensus-Consensus pair: %d (expected: +1)" % board.calculate_tile_adjacency_pressure(Vector2i(1, 1)))
	print("  Crackpot-Consensus pair: %d (expected: -1)" % board.calculate_tile_adjacency_pressure(Vector2i(1, 2)))
	print("  Total board pressure: %d" % board.calculate_total_adjacency_pressure())
	print()
	
	# Test integration reduction
	print("After integrating consensus tiles:")
	consensus1.integrate()
	consensus2.integrate()
	print("  Total board pressure: %d (penalties reduced 50%%)" % board.calculate_total_adjacency_pressure())
