# ResearchSystemRegistry.gd
# Call this to register research minigame classes with the save/load system
class_name ResearchSystemRegistry
extends RefCounted

static func register_classes() -> void:
	# Register all research minigame classes
	LoadSystem.register_class("ResearchTile", ResearchTile)
	LoadSystem.register_class("ResearchBoard", ResearchBoard)
	LoadSystem.register_class("ResearchWeather", ResearchWeather)
	LoadSystem.register_class("SpellIntent", SpellIntent)
	LoadSystem.register_class("ResearchSession", ResearchSession)
	
	print("Research minigame classes registered with save/load system")

# Auto-register when this class is loaded (if you want automatic registration)
static func _static_init() -> void:
	register_classes()
