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
	# Android can synthesize a mouse click immediately after a touch. A single
	# tap must still rotate exactly once.
	game.active = Tetromino.new("T")
	var rotation_before: int = game.active.rotation
	var touch_press := InputEventScreenTouch.new()
	touch_press.index = 0
	touch_press.position = Vector2(180, 300)
	touch_press.pressed = true
	game._input(touch_press)
	var touch_release := InputEventScreenTouch.new()
	touch_release.index = 0
	touch_release.position = Vector2(180, 300)
	touch_release.pressed = false
	game._input(touch_release)
	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.position = Vector2(180, 300)
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	game._input(emulated_mouse)
	if game.active.rotation != rotation_before + 1:
		push_error("A touch followed by its emulated mouse click should rotate only once")
		quit(1)
		return
	# Dragging should move during the drag instead of batching movement at release.
	game.active = Tetromino.new("T")
	var drag_press := InputEventScreenTouch.new()
	drag_press.index = 0
	drag_press.position = Vector2(100, 300)
	drag_press.pressed = true
	game._input(drag_press)
	var horizontal_drag := InputEventScreenDrag.new()
	horizontal_drag.index = 0
	horizontal_drag.position = Vector2(115, 300)
	game._input(horizontal_drag)
	if game.active.position.x != 4 or game.active.rotation != 0:
		push_error("Horizontal touch drag should move one cell immediately without rotating")
		quit(1)
		return
	var drag_release := InputEventScreenTouch.new()
	drag_release.index = 0
	drag_release.position = Vector2(115, 300)
	drag_release.pressed = false
	game._input(drag_release)
	if game.active.position.x != 4 or game.active.rotation != 0:
		push_error("Releasing a completed horizontal drag should not add another action")
		quit(1)
		return
	var down_press := InputEventScreenTouch.new()
	down_press.index = 0
	down_press.position = Vector2(180, 250)
	down_press.pressed = true
	game._input(down_press)
	var down_drag := InputEventScreenDrag.new()
	down_drag.index = 0
	down_drag.position = Vector2(180, 263)
	game._input(down_drag)
	if game.active.position.y != 1:
		push_error("Downward touch drag should soft-drop one cell immediately")
		quit(1)
		return
	print("PASS: Space starts the game")
	quit(0)
