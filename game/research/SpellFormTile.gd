## A placeable tile that can be inserted into a SpellForm. Immutable, but when 
class_name SpellFormTile
extends RegisteredObject

@export var category: String # "consensus", "tenuous", "crackpot"

@export var base_effect := {}
@export var volatility_profile := {}
@export var integration_max := 5
@export var inertia_max := 5

# Arbitrary adjacency descriptions
# Outgoing effect example:
#{
	#"target_tag": "consensus",
	#"effect": {
		#"type": "resource_delta",
		#"resource": "cohesion",
		#"amount": 1
	#},
	#"conditions": {
		#"min_integration": 1
	#}
#}
@export var outgoing_adjacency_effects:Array[AdjacencyEffect] = []
# Incoming modifier example:
#{
	#"source_category": "crackpot",
	#"modifier": {
		#"type": "multiplier",
		#"resource": "volatility",
		#"value": 1.25
	#}
#}
@export var incoming_modifiers := []

@export var synergies: Array[SynergyEffect] = []

var effects: Array[String] = []
var domain: SpellDomain
