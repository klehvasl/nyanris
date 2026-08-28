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
	game.start_game()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/gameplay.png")
	game.state = game.State.GAME_OVER
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/output/game_over.png")
	quit(0)
