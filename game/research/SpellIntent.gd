# SpellIntent.gd
class_name SpellIntent
extends RefCounted

enum SpellDomain {
	LIGHT,
	SHADOW,
	FIRE,
	ICE,
	FORCE,
	MIND,
	LIFE,
	DEATH
}

# Intent definition
var domain: SpellDomain
var constraints: Array[String] = []  # e.g., ["low_intensity", "non_combat", "sustained"]
var desired_effects: Array[String] = []  # e.g., ["illumination", "warmth"]

# Requirements for completion
var min_cohesion_required: int = 6
var min_integrated_tiles: int = 4
var min_adjacency_links: int = 5

# Available tile pool (tile names that can be drawn)
var available_tile_pool: Array[String] = []

func _init(
	p_domain: SpellDomain = SpellDomain.LIGHT,
	p_constraints: Array[String] = [],
	p_desired_effects: Array[String] = []
) -> void:
	domain = p_domain
	constraints = p_constraints.duplicate()
	desired_effects = p_desired_effects.duplicate()
	_generate_tile_pool()
	_calculate_requirements()

# Generate tile pool based on domain and constraints
func _generate_tile_pool() -> void:
	available_tile_pool.clear()
	
	# Base tiles for domain
	match domain:
		SpellDomain.LIGHT:
			available_tile_pool.append_array([
				"Photon Theory",
				"Wave Propagation",
				"Luminous Essence",
				"Prismatic Refraction",
				"Radiant Flux"
			])
		SpellDomain.SHADOW:
			available_tile_pool.append_array([
				"Umbral Theory",
				"Light Absorption",
				"Darkness Concentration",
				"Shadow Weaving",
				"Void Resonance"
			])
		SpellDomain.FIRE:
			available_tile_pool.append_array([
				"Combustion Theory",
				"Heat Transfer",
				"Thermal Runaway",
				"Oxidation Cascade",
				"Flame Geometry"
			])
		SpellDomain.ICE:
			available_tile_pool.append_array([
				"Crystallization",
				"Heat Extraction",
				"Phase Transition",
				"Frost Nucleation",
				"Entropic Sink"
			])
		SpellDomain.FORCE:
			available_tile_pool.append_array([
				"Vector Mechanics",
				"Momentum Transfer",
				"Kinetic Shaping",
				"Pressure Manipulation",
				"Inertial Control"
			])
		SpellDomain.MIND:
			available_tile_pool.append_array([
				"Neural Resonance",
				"Thought Patterns",
				"Synaptic Bridge",
				"Memory Encoding",
				"Perception Filter"
			])
		SpellDomain.LIFE:
			available_tile_pool.append_array([
				"Cellular Stimulation",
				"Vital Essence",
				"Growth Acceleration",
				"Metabolic Boost",
				"Regenerative Matrix"
			])
		SpellDomain.DEATH:
			available_tile_pool.append_array([
				"Necrotic Theory",
				"Life Drain",
				"Decay Acceleration",
				"Soul Separation",
				"Entropy Channeling"
			])
	
	# Add constraint-specific tiles
	for constraint in constraints:
		match constraint:
			"low_intensity":
				available_tile_pool.append("Controlled Manifestation")
				available_tile_pool.append("Gentle Application")
			"non_combat":
				available_tile_pool.append("Peaceful Intent")
				available_tile_pool.append("Utility Focus")
			"sustained":
				available_tile_pool.append("Duration Extension")
				available_tile_pool.append("Stable Maintenance")
			"instant":
				available_tile_pool.append("Rapid Discharge")
				available_tile_pool.append("Burst Activation")

# Calculate requirements based on constraints and effects
func _calculate_requirements() -> void:
	# Base requirements
	min_cohesion_required = 6
	min_integrated_tiles = 4
	min_adjacency_links = 5
	
	# Adjust based on desired effects count
	var effect_count = desired_effects.size()
	if effect_count > 2:
		min_integrated_tiles += (effect_count - 2)
		min_adjacency_links += (effect_count - 2) * 2
	
	# Adjust based on constraints
	for constraint in constraints:
		match constraint:
			"low_intensity":
				min_cohesion_required -= 1
			"sustained":
				min_cohesion_required += 2
				min_adjacency_links += 2
			"instant":
				min_cohesion_required -= 1

# Check if spell completion requirements are met
func check_completion_requirements(
	current_cohesion: int,
	integrated_count: int,
	adjacency_count: int
) -> Dictionary:
	var result = {
		"can_complete": false,
		"cohesion_met": false,
		"integrated_met": false,
		"adjacency_met": false,
		"missing_requirements": []
	}
	
	result.cohesion_met = current_cohesion >= min_cohesion_required
	result.integrated_met = integrated_count >= min_integrated_tiles
	result.adjacency_met = adjacency_count >= min_adjacency_links
	
	if not result.cohesion_met:
		result.missing_requirements.append("Cohesion: %d/%d" % [current_cohesion, min_cohesion_required])
	
	if not result.integrated_met:
		result.missing_requirements.append("Integrated tiles: %d/%d" % [integrated_count, min_integrated_tiles])
	
	if not result.adjacency_met:
		result.missing_requirements.append("Adjacency links: %d/%d" % [adjacency_count, min_adjacency_links])
	
	result.can_complete = result.cohesion_met and result.integrated_met and result.adjacency_met
	
	return result

# Get domain name as string
func get_domain_name() -> String:
	match domain:
		SpellDomain.LIGHT: return "Light"
		SpellDomain.SHADOW: return "Shadow"
		SpellDomain.FIRE: return "Fire"
		SpellDomain.ICE: return "Ice"
		SpellDomain.FORCE: return "Force"
		SpellDomain.MIND: return "Mind"
		SpellDomain.LIFE: return "Life"
		SpellDomain.DEATH: return "Death"
	return "Unknown"

# Get formatted intent description
func get_description() -> String:
	var desc = "Domain: %s\n" % get_domain_name()
	
	if not constraints.is_empty():
		desc += "Constraints: %s\n" % ", ".join(constraints)
	
	if not desired_effects.is_empty():
		desc += "Effects: %s\n" % ", ".join(desired_effects)
	
	desc += "\nRequirements:\n"
	desc += "  Cohesion: %d+\n" % min_cohesion_required
	desc += "  Integrated tiles: %d+\n" % min_integrated_tiles
	desc += "  Adjacency links: %d+\n" % min_adjacency_links
	
	return desc

# Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"__class__": "SpellIntent",
		"domain": domain,
		"constraints": constraints.duplicate(),
		"desired_effects": desired_effects.duplicate(),
		"min_cohesion_required": min_cohesion_required,
		"min_integrated_tiles": min_integrated_tiles,
		"min_adjacency_links": min_adjacency_links,
		"available_tile_pool": available_tile_pool.duplicate()
	}

# Deserialize from dictionary
static func from_dict(dict: Dictionary) -> SpellIntent:
	var intent = SpellIntent.new()
	intent.domain = dict.get("domain", SpellDomain.LIGHT)
	intent.constraints = dict.get("constraints", []).duplicate()
	intent.desired_effects = dict.get("desired_effects", []).duplicate()
	intent.min_cohesion_required = dict.get("min_cohesion_required", 6)
	intent.min_integrated_tiles = dict.get("min_integrated_tiles", 4)
	intent.min_adjacency_links = dict.get("min_adjacency_links", 5)
	intent.available_tile_pool = dict.get("available_tile_pool", []).duplicate()
	return intent
