class_name AdjacencyResolver
extends RefCounted

# -----------------------------
# PUBLIC: preview tile placement
# -----------------------------
static func preview_tile_placement(
	placed_tile: SpellFormSlot,
	neighbor_tiles: Array[SpellFormSlot]
) -> ResearchPlacementPreview:

	var preview := ResearchPlacementPreview.new()
	
	# Apply adjacency effects
	for neighbor in neighbor_tiles:
		_apply_adjacency_effects_between(placed_tile, neighbor, preview)
		_apply_adjacency_effects_between(neighbor, placed_tile, preview)
	
	# Apply synergies
	_apply_synergies(placed_tile, neighbor_tiles, preview)
	
	# Apply placement cost + integration/inertia for the placed tile
	_apply_placement_costs(placed_tile, preview)
	
	return preview
	
static func _apply_adjacency_effects_between(source: SpellFormSlot, target: SpellFormSlot, preview: ResearchPlacementPreview) -> void:
	var outgoing_effects = source.outgoing_adjacency_effects
	# Sort by priority descending
	outgoing_effects.sort_custom(func(a, b):
		var pa = a.extras.get("priority", 0)
		var pb = b.extras.get("priority", 0)
		return pb - pa
	)

	for effect in outgoing_effects:
		if not effect.matches(source, target):
			continue
		
		var scaled_amount = effect.amount
		if effect.extras.has("scaling_curve") and typeof(effect.extras.scaling_curve) == TYPE_CALLABLE:
			scaled_amount = effect.extras.scaling_curve(scaled_amount, source, target)
		
		var final_effect = _apply_incoming_modifiers(target, effect, scaled_amount)
		_apply_effect_to_preview(final_effect, preview, target)

static func _apply_incoming_modifiers(target: SpellFormSlot, effect: AdjacencyEffect, amount: float) -> Dictionary:
	var modified := {
		"effect_type": effect.effect_type,
		"resource": effect.resource,
		"amount": amount,
		"note": effect.extras.get("note", "")
	}

	for mod in target.adjacency_effects.get("incoming_modifiers", []):
		if mod.source_category != effect.source_category and effect.source_category != "":
			continue
		
		match mod.modifier.type:
			"multiplier":
				modified.amount *= mod.modifier.value
			"add":
				modified.amount += mod.modifier.value
			_:
				push_warning("Unknown incoming modifier type: %s" % mod.modifier.type)
	
	return modified

static func _apply_effect_to_preview(effect_dict: Dictionary, preview: ResearchPlacementPreview, target_tile: SpellFormSlot) -> void:
	var tile_id = target_tile.id

	match effect_dict.effect_type:
		"resource_delta":
			if not preview.resource_deltas.has(tile_id):
				preview.resource_deltas[tile_id] = {}
			var res = effect_dict.get("resource")
			preview.resource_deltas[tile_id][res] = preview.resource_deltas[tile_id].get(res, 0) + effect_dict.amount
		
		"volatility":
			preview.volatility_deltas[tile_id] = preview.volatility_deltas.get(tile_id, 0) + effect_dict.amount
		
		"cohesion":
			preview.cohesion_deltas[tile_id] = preview.cohesion_deltas.get(tile_id, 0) + effect_dict.amount
		
		"integration":
			preview.integration_deltas[tile_id] = preview.integration_deltas.get(tile_id, 0) + effect_dict.amount
		
		"inertia":
			preview.inertia_deltas[tile_id] = preview.inertia_deltas.get(tile_id, 0) + effect_dict.amount
		
		"note":
			if not preview.notes.has(tile_id):
				preview.notes[tile_id] = []
			preview.notes[tile_id].append(effect_dict.note)
		
		_:
			push_warning("Unknown effect type: %s" % effect_dict.effect_type)

static func _apply_synergies(placed_tile: SpellFormSlot, neighbor_tiles: Array[SpellFormSlot], preview: ResearchPlacementPreview) -> void:

	for synergy in placed_tile.synergies:
		if not synergy.is_active(placed_tile, neighbor_tiles):
			continue
		
		# Determine affected tiles (placed tile + matching neighbors)
		var affected_tiles := [placed_tile]
		for neighbor in neighbor_tiles:
			if neighbor.category in synergy.pattern:
				affected_tiles.append(neighbor)
		
		for tile in affected_tiles:
			var effect_dict := {
				"effect_type": synergy.effect_type,
				"resource": synergy.resource,
				"amount": synergy.get_scaled_amount(placed_tile),
				"note": synergy.extras.get("note", "")
			}
			_apply_effect_to_preview(effect_dict, preview, tile)
			
			if effect_dict.note != "":
				if not preview.synergy_notes.has(tile.id):
					preview.synergy_notes[tile.id] = []
				preview.synergy_notes[tile.id].append(effect_dict.note)

static func _apply_placement_costs(placed_tile: SpellFormSlot, preview: ResearchPlacementPreview) -> void:
	preview.focus_cost += placed_tile.placement_cost.get("focus", 0)
	preview.will_cost += placed_tile.placement_cost.get("will", 0)
	preview.intuition_cost += placed_tile.placement_cost.get("intuition", 0)

	# Integration and inertia for the placed tile itself
	preview.integration_deltas[placed_tile.id] = placed_tile.integration_per_placement
	preview.inertia_deltas[placed_tile.id] = placed_tile.integration_per_placement * placed_tile.inertia_per_integration
