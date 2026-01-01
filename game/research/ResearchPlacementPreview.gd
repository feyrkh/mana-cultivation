class_name ResearchPlacementPreview
extends RefCounted

# --- Per-tile deltas ---
var resource_deltas := {}       # SpellFormSlot -> {resource_name: delta}
var volatility_deltas := {}     # SpellFormSlot -> delta
var cohesion_deltas := {}       # SpellFormSlot -> delta
var integration_deltas := {}    # SpellFormSlot -> delta
var inertia_deltas := {}        # SpellFormSlot -> delta

# --- Placement costs for the placed tile itself ---
var focus_cost := 0.0
var will_cost := 0.0
var intuition_cost := 0.0

# --- Notes ---
var notes := {}          # SpellFormSlot -> array of strings
var synergy_notes := {}  # SpellFormSlot -> array of strings
