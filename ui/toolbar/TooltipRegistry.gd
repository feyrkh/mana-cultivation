# TooltipRegistry.gd
# Central registry for all tooltip definitions
class_name TooltipRegistry
extends RefCounted

var tooltips: Dictionary = {}  # tooltip_id -> {title, body, links}

func register_tooltip(tooltip_id: String, title: String, body: String, links: Array[Dictionary] = []) -> void:
	tooltips[tooltip_id] = {
		"title": title,
		"body": body,
		"links": links
	}

func get_tooltip_data(tooltip_id: String) -> Dictionary:
	if tooltips.has(tooltip_id):
		return tooltips[tooltip_id]
	return {}

func has_tooltip(tooltip_id: String) -> bool:
	return tooltips.has(tooltip_id)

func create_tooltip_content(tooltip_id: String) -> TooltipContent:
	if not has_tooltip(tooltip_id):
		push_warning("Tooltip not found: " + tooltip_id)
		return null
	
	var data = get_tooltip_data(tooltip_id)
	var content = TooltipContent.new()
	content.set_data(tooltip_id, data.title, data.body, data.get("links", []))
	return content
