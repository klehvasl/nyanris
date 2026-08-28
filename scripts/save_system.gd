class_name SaveSystem
extends RefCounted

const PATH := "user://cozy_cat_blocks.cfg"

static func load_high_score() -> int:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		return int(config.get_value("scores", "high_score", 0))
	return 0

static func save_high_score(value: int) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("scores", "high_score", value)
	config.save(PATH)

static func load_setting(key: String, default_value: Variant) -> Variant:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		return config.get_value("settings", key, default_value)
	return default_value

static func save_setting(key: String, value: Variant) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("settings", key, value)
	config.save(PATH)
