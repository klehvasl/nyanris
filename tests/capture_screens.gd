extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/output"))
	root.get_texture().get_image().save_png("res://tests/output/title.png")
	game.open_level_select()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/level_select.png")
	game.first_gameplay_controls_pending = true
	game.start_game()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/controls.png")
	game.close_controls_screen()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/gameplay.png")
	game.lines = 30
	game.add_crowd_cats(29)
	game.add_crowd_cats(1, true)
	game.cat_crowd_jump_timer = game.CAT_CROWD_JUMP_SECONDS * 0.5
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/cat_crowd.png")
	game.score = 4321
	game.state = game.State.ENDING
	game.ending_timer = 4.2
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/stargazer_ending.png")
	game.score = 12345
	game.ending_timer = 1.0
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/lantern_ending_opening.png")
	game.ending_timer = 20.0
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/lantern_ending.png")
	game.state = game.State.GAME_OVER
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/game_over.png")
	game.state = game.State.NAME_ENTRY
	game.score = 12345
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/name_entry.png")
	game.high_scores.clear()
	game.high_scores.append({"name": "NYAN", "score": 12345, "level": 4, "lines": 42})
	game.high_scores.append({"name": "CAT", "score": 9876, "level": 3, "lines": 31})
	game.high_scores_return_state = game.State.GAME_OVER
	game.state = game.State.HIGH_SCORES
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/high_scores.png")
	quit(0)
