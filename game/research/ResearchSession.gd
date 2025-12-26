# ResearchSession.gd
class_name ResearchSession
extends RefCounted

signal session_started()
signal session_ended(reason: String, success: bool)
signal turn_advanced(turn_number: int)
signal weather_changed(new_weather: ResearchWeather)
signal resource_changed(resource_name: String, new_value: int)
signal cohesion_changed(new_value: int)
signal action_performed(action_name: String, result: Dictionary)

# Session state
enum SessionState {
	NOT_STARTED,
	IN_PROGRESS,
	ENDED
}

var state: SessionState = SessionState.NOT_STARTED

# Resources
const STARTING_FOCUS: int = 10
const STARTING_INSIGHT: int = 2
const INSIGHT_SOFT_CAP: int = 6
const STARTING_COHESION: int = 10
const MAX_INTEGRATION_PER_SESSION: int = 3

var focus: int = STARTING_FOCUS
var insight: int = STARTING_INSIGHT
var cohesion: int = STARTING_COHESION
var integrations_this_session: int = 0

# Core components
var spell_intent: SpellIntent
var board: ResearchBoard
var current_weather: ResearchWeather
var turn_number: int = 0
var turns_until_weather_change: int = 3

# Tile management
var tile_deck: Array[String] = []  # Available tiles from pool
var hand: Array[ResearchTile] = []  # Tiles currently available to place

func _init(p_intent: SpellIntent = null) -> void:
	if p_intent != null:
		spell_intent = p_intent
	else:
		spell_intent = SpellIntent.new()
	
	board = ResearchBoard.new()
	current_weather = ResearchWeather.new(ResearchWeather.WeatherType.CLEAR, 3)
	_initialize_deck()

# Initialize tile deck from spell intent
func _initialize_deck() -> void:
	tile_deck = spell_intent.available_tile_pool.duplicate()
	tile_deck.shuffle()

# Start a new session
func start_session() -> void:
	if state == SessionState.IN_PROGRESS:
		push_warning("Session already in progress")
		return
	
	state = SessionState.IN_PROGRESS
	focus = STARTING_FOCUS
	insight = STARTING_INSIGHT
	integrations_this_session = 0
	turn_number = 0
	turns_until_weather_change = 3
	
	# Generate starting weather
	current_weather = ResearchWeather.generate_random_weather()
	
	session_started.emit()
	weather_changed.emit(current_weather)

# End the session
func end_session(reason: String, success: bool) -> void:
	if state != SessionState.IN_PROGRESS:
		return
	
	state = SessionState.ENDED
	session_ended.emit(reason, success)

# Advance to next turn
func advance_turn() -> void:
	if state != SessionState.IN_PROGRESS:
		return
	
	turn_number += 1
	turn_advanced.emit(turn_number)
	
	# Apply weather effects
	var weather_effects = current_weather.apply_turn_effects(self)
	if weather_effects.insight_change != 0:
		add_insight(weather_effects.insight_change)
	if weather_effects.cohesion_change != 0:
		modify_cohesion(weather_effects.cohesion_change, weather_effects.message)
	
	# Apply adjacency pressure
	var adjacency_pressure = _calculate_weather_modified_adjacency()
	if adjacency_pressure != 0:
		modify_cohesion(adjacency_pressure, "Adjacency pressure: %+d" % adjacency_pressure)
	
	# Advance weather
	turns_until_weather_change -= 1
	if turns_until_weather_change <= 0:
		_change_weather()
	
	# Deduct focus
	focus -= 1
	resource_changed.emit("focus", focus)
	
	# Check for session end
	if focus <= 0:
		end_session("Focus depleted", false)
	elif cohesion <= 0:
		end_session("Theory collapsed", false)

# Calculate adjacency pressure with weather modifiers
func _calculate_weather_modified_adjacency() -> int:
	var base_pressure = board.calculate_total_adjacency_pressure()
	
	# Apply weather modifiers if chaotic
	if current_weather.weather_type == ResearchWeather.WeatherType.CHAOTIC:
		# Double crackpot penalties
		var additional_penalty = 0
		var all_tiles = board.get_all_tiles()
		for tile in all_tiles:
			if tile.tag == ResearchTile.TileTag.CRACKPOT:
				var tile_pressure = board.calculate_tile_adjacency_pressure(tile.board_position)
				if tile_pressure < 0:
					additional_penalty += tile_pressure
		return base_pressure + additional_penalty
	
	return base_pressure

# Change weather
func _change_weather() -> void:
	current_weather = ResearchWeather.generate_random_weather()
	turns_until_weather_change = 3
	weather_changed.emit(current_weather)

# Add insight
func add_insight(amount: int) -> void:
	insight = clampi(insight + amount, 0, INSIGHT_SOFT_CAP)
	resource_changed.emit("insight", insight)

# Spend insight
func spend_insight(amount: int) -> bool:
	if insight < amount:
		return false
	insight -= amount
	resource_changed.emit("insight", insight)
	return true

# Modify cohesion
func modify_cohesion(amount: int, reason: String = "") -> void:
	var old_cohesion = cohesion
	cohesion = max(0, cohesion + amount)
	cohesion_changed.emit(cohesion)
	
	if cohesion <= 0 and old_cohesion > 0:
		end_session("Cohesion collapsed to zero", false)

# Count consensus tiles for weather effects
func count_consensus_tiles() -> int:
	var count = 0
	for tile in board.get_all_tiles():
		if tile.tag == ResearchTile.TileTag.CONSENSUS:
			count += 1
	return count

# ============================================
# ACTIONS
# ============================================

# Action: Place tile
func action_place_tile(tile: ResearchTile, position: Vector2i) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"cohesion_change": 0
	}
	
	if focus < 1:
		result.message = "Not enough Focus"
		return result
	
	if not board.is_empty(position):
		result.message = "Position already occupied"
		return result
	
	# Place tile at integration level 0
	tile.integration_level = 0
	if not board.place_tile(tile, position):
		result.message = "Failed to place tile"
		return result
	
	# Deduct focus
	focus -= 1
	resource_changed.emit("focus", focus)
	
	# Apply volatility penalty
	var volatility_penalty = -int(tile.get_current_volatility())
	modify_cohesion(volatility_penalty, "Tile volatility: %d" % volatility_penalty)
	result.cohesion_change = volatility_penalty
	
	result.success = true
	result.message = "Placed %s" % tile.tile_name
	action_performed.emit("place_tile", result)
	
	return result

# Action: Integrate tile
func action_integrate_tile(position: Vector2i) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"cohesion_change": 0,
		"insight_cost": 0
	}
	
	var tile = board.get_tile(position)
	if tile == null:
		result.message = "No tile at position"
		return result
	
	if not tile.can_integrate():
		result.message = "Tile already at max integration"
		return result
	
	if integrations_this_session >= MAX_INTEGRATION_PER_SESSION:
		result.message = "Maximum integrations per session reached"
		return result
	
	# Calculate insight cost
	var base_cost = 1
	match tile.tag:
		ResearchTile.TileTag.CONSENSUS:
			base_cost = 1
		ResearchTile.TileTag.TENUOUS:
			base_cost = 2
		ResearchTile.TileTag.CRACKPOT:
			base_cost = 3
	
	# Apply level scaling
	var level_multiplier = tile.integration_level + 1
	var insight_cost = base_cost * level_multiplier
	
	# Apply weather modifier
	if current_weather.weather_type == ResearchWeather.WeatherType.DOGMATIC:
		insight_cost = max(1, insight_cost - 1)
	elif current_weather.weather_type == ResearchWeather.WeatherType.RIGID and tile.tag == ResearchTile.TileTag.CRACKPOT:
		insight_cost += 1
	
	result.insight_cost = insight_cost
	
	if focus < 1:
		result.message = "Not enough Focus"
		return result
	
	if not spend_insight(insight_cost):
		result.message = "Not enough Insight (need %d)" % insight_cost
		return result
	
	# Integrate the tile
	tile.integrate()
	integrations_this_session += 1
	
	# Deduct focus
	focus -= 1
	resource_changed.emit("focus", focus)
	
	# Apply cohesion change
	var cohesion_change = tile.get_integration_cohesion_change()
	if cohesion_change != 0:
		modify_cohesion(cohesion_change, "Integration: %+d" % cohesion_change)
		result.cohesion_change = cohesion_change
	
	result.success = true
	result.message = "Integrated %s to level %d" % [tile.tile_name, tile.integration_level]
	action_performed.emit("integrate_tile", result)
	
	return result

# Action: Examine source (draw tiles)
func action_examine_source() -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"tiles_drawn": []
	}
	
	if focus < 1:
		result.message = "Not enough Focus"
		return result
	
	# Determine number of tiles to draw
	var tiles_to_draw = 2
	if current_weather.weather_type == ResearchWeather.WeatherType.STAGNANT:
		tiles_to_draw = 1
	
	# Draw tiles
	for i in range(tiles_to_draw):
		if tile_deck.is_empty():
			_initialize_deck()  # Reshuffle if empty
		
		if not tile_deck.is_empty():
			var tile_name = tile_deck.pop_back()
			var tile = _create_tile_from_name(tile_name)
			result.tiles_drawn.append(tile)
	
	if result.tiles_drawn.is_empty():
		result.message = "No tiles available"
		return result
	
	# Deduct focus
	focus -= 1
	resource_changed.emit("focus", focus)
	
	result.success = true
	result.message = "Drew %d tile(s)" % result.tiles_drawn.size()
	action_performed.emit("examine_source", result)
	
	return result

# Action: Stabilize theory
func action_stabilize_theory() -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"cohesion_change": 0
	}
	
	if focus < 1:
		result.message = "Not enough Focus"
		return result
	
	if not spend_insight(1):
		result.message = "Not enough Insight (need 1)"
		return result
	
	# Deduct focus
	focus -= 1
	resource_changed.emit("focus", focus)
	
	# Add cohesion
	modify_cohesion(3, "Stabilization: +3")
	result.cohesion_change = 3
	
	result.success = true
	result.message = "Theory stabilized (+3 Cohesion)"
	action_performed.emit("stabilize_theory", result)
	
	return result

# Action: Speculative leap
func action_speculative_leap() -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"tile_generated": null,
		"cohesion_change": -2
	}
	
	if focus < 2:
		result.message = "Not enough Focus (need 2)"
		return result
	
	if not spend_insight(2):
		result.message = "Not enough Insight (need 2)"
		return result
	
	# Deduct focus
	focus -= 2
	resource_changed.emit("focus", focus)
	
	# Generate powerful crackpot tile
	var tile = _generate_crackpot_tile()
	result.tile_generated = tile
	
	# Apply cohesion penalty
	modify_cohesion(-2, "Speculative leap: -2")
	
	result.success = true
	result.message = "Generated crackpot theory: %s" % tile.tile_name
	action_performed.emit("speculative_leap", result)
	
	return result

# Action: Attempt to complete spell
func action_complete_spell() -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"requirements_met": false,
		"check_result": {}
	}
	
	var integrated_count = board.count_integrated_tiles()
	var adjacency_count = board.count_adjacency_links()
	
	var check = spell_intent.check_completion_requirements(cohesion, integrated_count, adjacency_count)
	result.check_result = check
	
	if check.can_complete:
		result.success = true
		result.requirements_met = true
		result.message = "Spell successfully completed!"
		end_session("Spell completed", true)
	else:
		result.message = "Requirements not met:\n" + "\n".join(check.missing_requirements)
	
	action_performed.emit("complete_spell", result)
	return result

# ============================================
# HELPER METHODS
# ============================================

# Create tile from name with appropriate properties
func _create_tile_from_name(tile_name: String) -> ResearchTile:
	var tag: ResearchTile.TileTag
	var base_volatility: int
	var base_effect: Dictionary = {}
	
	# Determine tag and properties based on name patterns
	if tile_name.contains("Theory") or tile_name.contains("Propagation") or tile_name.contains("Mechanics"):
		tag = ResearchTile.TileTag.CONSENSUS
		base_volatility = 1
		base_effect = {"type": "stable_power", "value": 10}
	elif tile_name.contains("Resonance") or tile_name.contains("Flux") or tile_name.contains("Weaving"):
		tag = ResearchTile.TileTag.TENUOUS
		base_volatility = 2
		base_effect = {"type": "moderate_power", "value": 15}
	else:
		# Default to tenuous
		tag = ResearchTile.TileTag.TENUOUS
		base_volatility = 2
		base_effect = {"type": "moderate_power", "value": 15}
	
	return ResearchTile.new(tile_name, tag, base_effect, base_volatility)

# Generate a powerful crackpot tile
func _generate_crackpot_tile() -> ResearchTile:
	var crackpot_names = [
		"Reality Rewrite",
		"Paradox Engine",
		"Chaos Infusion",
		"Forbidden Synthesis",
		"Wild Conjecture",
		"Heretical Principle"
	]
	
	var name = crackpot_names[randi() % crackpot_names.size()]
	var effect = {"type": "powerful_effect", "value": 30}
	
	return ResearchTile.new(name, ResearchTile.TileTag.CRACKPOT, effect, 3)

# Serialize to dictionary
func to_dict() -> Dictionary:
	var hand_data: Array = []
	for tile in hand:
		hand_data.append(tile.to_dict())
	
	return {
		"__class__": "ResearchSession",
		"state": state,
		"focus": focus,
		"insight": insight,
		"cohesion": cohesion,
		"integrations_this_session": integrations_this_session,
		"spell_intent": spell_intent.to_dict(),
		"board": board.to_dict(),
		"current_weather": current_weather.to_dict(),
		"turn_number": turn_number,
		"turns_until_weather_change": turns_until_weather_change,
		"tile_deck": tile_deck.duplicate(),
		"hand": hand_data
	}

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> ResearchSession:
	var session = ResearchSession.new()
	
	session.state = dict.get("state", SessionState.NOT_STARTED)
	session.focus = dict.get("focus", STARTING_FOCUS)
	session.insight = dict.get("insight", STARTING_INSIGHT)
	session.cohesion = dict.get("cohesion", STARTING_COHESION)
	session.integrations_this_session = dict.get("integrations_this_session", 0)
	
	var intent_dict = dict.get("spell_intent", {})
	session.spell_intent = SpellIntent.from_dict(intent_dict)
	
	var board_dict = dict.get("board", {})
	session.board = ResearchBoard.from_dict(board_dict)
	
	var weather_dict = dict.get("current_weather", {})
	session.current_weather = ResearchWeather.from_dict(weather_dict)
	
	session.turn_number = dict.get("turn_number", 0)
	session.turns_until_weather_change = dict.get("turns_until_weather_change", 3)
	session.tile_deck = dict.get("tile_deck", []).duplicate()
	
	var hand_data = dict.get("hand", [])
	for tile_dict in hand_data:
		if tile_dict is Dictionary:
			session.hand.append(ResearchTile.from_dict(tile_dict))
	
	return session
