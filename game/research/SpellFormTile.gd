## A placeable tile that can be inserted into a SpellForm. Immutable, but when 
class_name SpellFormTile
extends RegisteredObject

@export var label: String # "Optical Refraction"
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

## Draws this tile onto a Control. Call from within _draw().
## target: The Control to draw on
## rect: The rectangle to draw within
## text_color: Color for the label text
func draw_tile(target: Control, rect: Rect2, text_color: Color = Color.BLACK) -> void:
	# White fill
	target.draw_rect(rect, Color.WHITE)

	# Black outline
	var outline_width := 1.0
	target.draw_rect(Rect2(rect.position, Vector2(rect.size.x, outline_width)), Color.BLACK)
	target.draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - outline_width), Vector2(rect.size.x, outline_width)), Color.BLACK)
	target.draw_rect(Rect2(rect.position, Vector2(outline_width, rect.size.y)), Color.BLACK)
	target.draw_rect(Rect2(Vector2(rect.end.x - outline_width, rect.position.y), Vector2(outline_width, rect.size.y)), Color.BLACK)

	# Draw label as multi-line text (split on spaces)
	var lines = label.split(" ")
	for i in lines.size():
		_draw_centered_text_line(target, lines[i], rect, text_color, i, lines.size())

static func _draw_centered_text_line(target: Control, text: String, rect: Rect2, color: Color, line_index: int, total_lines: int) -> void:
	var font = ThemeDB.fallback_font
	var font_size = 10
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = rect.position + (rect.size - text_size) / 2.0
	# Offset based on line number, centered vertically around the middle
	var line_height = text_size.y * 0.75
	var total_height = line_height * total_lines
	var start_y = (rect.size.y - total_height) / 2.0 + text_size.y * 0.6
	text_pos.y = rect.position.y + start_y + line_height * line_index
	target.draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
