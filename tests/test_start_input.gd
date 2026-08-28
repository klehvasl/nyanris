extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	if game.state != game.State.TITLE:
		push_error("Game should begin on the title screen")
		quit(1)
		return
	var title_start := InputEventKey.new()
	title_start.physical_keycode = KEY_SPACE
	title_start.pressed = true
	game._input(title_start)
	await process_frame
	if game.state != game.State.LEVEL_SELECT:
		push_error("The title Start action should open level selection")
		quit(1)
		return
	var down := InputEventKey.new()
	down.physical_keycode = KEY_DOWN
	down.pressed = true
	game._input(down)
	await process_frame
	if game.state != game.State.LEVEL_SELECT or game.start_level != 5:
		push_error("Down should move to the second level row without starting the game")
		quit(1)
		return
	game.set_start_level(0)
	var click_position := Vector2(124, 450)
	var press := InputEventMouseButton.new()
	press.position = click_position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	game._input(press)
	var release := InputEventMouseButton.new()
	release.position = click_position
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	game._input(release)
	await process_frame
	if game.start_level != 1:
		push_error("Clicking level 1 in the selector should change the starting level")
		quit(1)
		return
	game.set_start_level(5)
	game.set_line_clear_seconds(0.27)
	if not is_equal_approx(game.line_clear_seconds, 0.27):
		push_error("Line-clear debug slider value should update runtime timing")
		quit(1)
		return
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	if game.state != game.State.PLAYING:
		push_error("Space should start the game")
		quit(1)
		return
	if game.level != 5:
		push_error("Selected debug level should become the starting level")
		quit(1)
		return
	game.hard_drop()
	if game.hard_drop_fx_timer <= 0.0 or game.hard_drop_landed_cells.size() != 4 or game.hard_drop_shock_pixels.size() != 12:
		push_error("Hard drop should begin the visual trail and impact overlay")
		quit(1)
		return
	game.retry_game()
	if game.state != game.State.PLAYING or game.score != 0 or game.lines != 0 or game.level != 5:
		push_error("Retry should immediately reset the current run at the selected starting level")
		quit(1)
		return
	print("PASS: Space starts the game")
	quit(0)
