# ResearchWeather.gd
class_name ResearchWeather
extends RefCounted

enum WeatherType {
	INSPIRED,
	DOGMATIC,
	CHAOTIC,
	STAGNANT,
	CLEAR,
	VOLATILE,
	HARMONIOUS,
	RIGID
}

var weather_type: WeatherType
var duration_remaining: int

func _init(p_type: WeatherType = WeatherType.CLEAR, p_duration: int = 3) -> void:
	weather_type = p_type
	duration_remaining = p_duration

# Get weather description
func get_description() -> String:
	match weather_type:
		WeatherType.INSPIRED:
			return "Inspired: Mind racing with possibilities"
		WeatherType.DOGMATIC:
			return "Dogmatic: Conventional wisdom feels safer"
		WeatherType.CHAOTIC:
			return "Chaotic: Wild theories clash violently"
		WeatherType.STAGNANT:
			return "Stagnant: Sources yield little"
		WeatherType.CLEAR:
			return "Clear: Balanced conditions"
		WeatherType.VOLATILE:
			return "Volatile: Instability pervades"
		WeatherType.HARMONIOUS:
			return "Harmonious: Consensus aligns easily"
		WeatherType.RIGID:
			return "Rigid: Radical ideas struggle"
	return "Unknown weather"

# Apply weather effects at start of turn
func apply_turn_effects(session: RefCounted) -> Dictionary:
	var effects: Dictionary = {
		"insight_change": 0,
		"cohesion_change": 0,
		"message": ""
	}
	
	match weather_type:
		WeatherType.INSPIRED:
			effects.insight_change = 1
			effects.message = "Inspiration strikes! +1 Insight"
		
		WeatherType.CHAOTIC:
			# Handled by session logic - doubles crackpot penalties
			effects.message = "Chaotic energies amplify radical contradictions"
		
		WeatherType.VOLATILE:
			effects.cohesion_change = -1
			effects.message = "Volatile conditions stress your theory (-1 Cohesion)"
		
		WeatherType.HARMONIOUS:
			if session.has_method("count_consensus_tiles"):
				var consensus_count = session.count_consensus_tiles()
				if consensus_count > 0:
					effects.cohesion_change = 1
					effects.message = "Harmonious alignment stabilizes consensus (+1 Cohesion)"
	
	return effects

# Get integration cost modifier
func get_integration_cost_modifier() -> int:
	match weather_type:
		WeatherType.DOGMATIC:
			return -1  # Reduces insight cost by 1
		WeatherType.RIGID:
			# Crackpot tiles cost +1 more insight
			return 0  # Handled in session logic
	return 0

# Get examine source tile count modifier
func get_examine_tile_modifier() -> int:
	match weather_type:
		WeatherType.STAGNANT:
			return -1  # Only 1 tile instead of 2
	return 0

# Get adjacency pressure modifier (multiplicative)
func get_adjacency_pressure_modifier(tile1: ResearchTile, tile2: ResearchTile) -> float:
	if weather_type == WeatherType.CHAOTIC:
		# Double crackpot penalties
		if tile1.tag == ResearchTile.TileTag.CRACKPOT or tile2.tag == ResearchTile.TileTag.CRACKPOT:
			return 2.0
	return 1.0

# Advance weather duration
func advance_turn() -> bool:
	duration_remaining -= 1
	return duration_remaining <= 0

# Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"__class__": "ResearchWeather",
		"weather_type": weather_type,
		"duration_remaining": duration_remaining
	}

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> ResearchWeather:
	var weather = ResearchWeather.new()
	weather.weather_type = dict.get("weather_type", WeatherType.CLEAR)
	weather.duration_remaining = dict.get("duration_remaining", 3)
	return weather

# Generate random weather
static func generate_random_weather() -> ResearchWeather:
	var weather_types = [
		WeatherType.INSPIRED,
		WeatherType.DOGMATIC,
		WeatherType.CHAOTIC,
		WeatherType.STAGNANT,
		WeatherType.CLEAR,
		WeatherType.VOLATILE,
		WeatherType.HARMONIOUS,
		WeatherType.RIGID
	]
	
	var random_type = weather_types[randi() % weather_types.size()]
	return ResearchWeather.new(random_type, 3)
