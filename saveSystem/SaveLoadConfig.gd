# SaveLoadConfig.gd
# Global configuration for the save/load system
extends Node

# Set to true for JSON, false for binary
const USE_JSON_FORMAT: bool = false

# File extensions
const JSON_EXT: String = ".json"
const BINARY_EXT: String = ".sav"

func get_extension() -> String:
	return JSON_EXT if USE_JSON_FORMAT else BINARY_EXT
