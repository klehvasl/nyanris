class_name SaveSystem
extends RefCounted

const PATH := "user://cozy_cat_blocks.cfg"
const MAX_HIGH_SCORES := 10

static func load_high_scores() -> Array[Dictionary]:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return []
	var stored = config.get_value("scores", "leaderboard", [])
	var entries: Array[Dictionary] = []
	if stored is Array:
		for item in stored:
			if item is Dictionary and item.has("score"):
				entries.append({
					"name": sanitize_player_name(str(item.get("name", "CAT"))),
					"score": maxi(0, int(item.score)),
					"level": maxi(0, int(item.get("level", 0))),
					"lines": maxi(0, int(item.get("lines", 0))),
				})
	# Preserve scores created by versions that only stored a single number.
	var legacy_score := int(config.get_value("scores", "high_score", 0))
	if entries.is_empty() and legacy_score > 0:
		entries.append({"name": "CAT", "score": legacy_score, "level": 0, "lines": 0})
	return sort_high_scores(entries)

static func qualifies_for_high_score(value: int, entries: Array[Dictionary]) -> bool:
	return value > 0 and (entries.size() < MAX_HIGH_SCORES or value > int(entries[-1].score))

static func add_high_score(player_name: String, value: int, level: int, lines: int) -> Array[Dictionary]:
	var entries := load_high_scores()
	entries.append({
		"name": sanitize_player_name(player_name),
		"score": maxi(0, value),
		"level": maxi(0, level),
		"lines": maxi(0, lines),
	})
	entries = sort_high_scores(entries)
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("scores", "leaderboard", entries)
	config.set_value("scores", "high_score", int(entries[0].score) if not entries.is_empty() else 0)
	config.save(PATH)
	return entries

static func sort_high_scores(entries: Array[Dictionary]) -> Array[Dictionary]:
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.score) == int(b.score):
			return int(a.get("lines", 0)) > int(b.get("lines", 0))
		return int(a.score) > int(b.score)
	)
	if entries.size() > MAX_HIGH_SCORES:
		entries.resize(MAX_HIGH_SCORES)
	return entries

static func sanitize_player_name(value: String) -> String:
	var cleaned := value.strip_edges().to_upper()
	var result := ""
	for character in cleaned:
		if character in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .-_":
			result += character
		if result.length() >= 10:
			break
	return result if not result.is_empty() else "CAT"

static func load_high_score() -> int:
	var entries := load_high_scores()
	return int(entries[0].score) if not entries.is_empty() else 0

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
