class_name HashUtil
extends RefCounted

static func string_to_float(input: String) -> float:
	if input.is_empty():
		return 0.0
	var hash_value = input.hash()
	# Convert to unsigned 32-bit range (0 to 4294967295)
	# The hash() function returns a signed int, so we need to handle negatives
	var unsigned_hash = hash_value & 0xFFFFFFFF
	# Normalize to 0.0 - 1.0
	return float(unsigned_hash) / 4294967295.0
