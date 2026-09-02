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
	if game.controls_visible:
		push_error("The automatic controls screen must wait for the first gameplay board")
		quit(1)
		return
	if game.scores_button.visible:
		push_error("High Scores must not cover the title screen")
		quit(1)
		return
	game.controls_visible = true
	game.update_menu_controls()
	if not game.controls_close_button.visible or game.controls_button.visible or game.music_button.visible:
		push_error("The first-time controls screen must behave as a modal")
		quit(1)
		return
	var controls_confirm := InputEventKey.new()
	controls_confirm.physical_keycode = KEY_ENTER
	controls_confirm.pressed = true
	game._input(controls_confirm)
	if game.controls_visible or game.controls_button.visible:
		push_error("Confirm must dismiss the controls screen without adding it to the title")
		quit(1)
		return
	if game.audio.MIX_RATE != 48000:
		push_error("Synthesized effects must match the 48 kHz mobile mixer")
		quit(1)
		return
	var has_master_limiter := false
	var master_bus := AudioServer.get_bus_index("Master")
	for effect_index in AudioServer.get_bus_effect_count(master_bus):
		if AudioServer.get_bus_effect(master_bus, effect_index) is AudioEffectLimiter:
			has_master_limiter = true
	if not has_master_limiter:
		push_error("The mobile mix must protect simultaneous music and effects with a limiter")
		quit(1)
		return
	for effect_id in ["rotate", "invalid", "soft_drop", "lock", "hard_drop", "double_clear", "triple_clear", "level_up", "ui_select", "ui_confirm", "ui_cancel", "pause", "resume", "game_over", "high_score", "name_saved"]:
		if not game.audio.synth_effects.has(effect_id):
			push_error("Missing synthesized sound effect: %s" % effect_id)
			quit(1)
			return
	if not ResourceLoader.exists(game.audio.ENDING_MUSIC_PATH):
		push_error("Missing Stargazer ending music")
		quit(1)
		return
	if not ResourceLoader.exists("res://assets/endings/stargazer/cat_sheet_aligned.png"):
		push_error("Missing aligned Stargazer cat animation")
		quit(1)
		return
	if not ResourceLoader.exists("res://assets/cat/golden_01.png"):
		push_error("Missing golden six-line cat")
		quit(1)
		return
	if not ResourceLoader.exists("res://assets/endings/lantern.png"):
		push_error("Missing Lantern ending sprite")
		quit(1)
		return
	game.score = game.LANTERN_ENDING_SCORE - 1
	if game.ending_name() != "STARGAZER":
		push_error("Scores below the Lantern threshold must receive Stargazer")
		quit(1)
		return
	game.score = game.LANTERN_ENDING_SCORE
	if game.ending_name() != "LANTERN":
		push_error("Scores at the Lantern threshold must receive Lantern")
		quit(1)
		return
	game.score = 0
	game.state = game.State.TITLE
	game.open_ending_preview(true)
	if game.state != game.State.ENDING or not game.ending_preview_mode or game.ending_name() != "LANTERN":
		push_error("The debug Lantern preview must open without playing for a score")
		quit(1)
		return
	game.complete_ending()
	if game.state != game.State.TITLE or game.ending_preview_mode or game.score != 0:
		push_error("Ending preview must return to its menu without submitting or retaining a preview score")
		quit(1)
		return
	var stargazer_preview_key := InputEventKey.new()
	stargazer_preview_key.physical_keycode = KEY_7
	stargazer_preview_key.pressed = true
	game._input(stargazer_preview_key)
	if game.state != game.State.ENDING or game.ending_name() != "STARGAZER":
		push_error("7 must open the Stargazer preview when running from the editor")
		quit(1)
		return
	game.complete_ending()
	var lantern_preview_key := InputEventKey.new()
	lantern_preview_key.physical_keycode = KEY_8
	lantern_preview_key.pressed = true
	game._input(lantern_preview_key)
	if game.state != game.State.ENDING or game.ending_name() != "LANTERN":
		push_error("8 must open the Lantern preview when running from the editor")
		quit(1)
		return
	game.complete_ending()
	var unrelated_key := InputEventKey.new()
	unrelated_key.physical_keycode = KEY_F2
	unrelated_key.pressed = true
	game._input(unrelated_key)
	if game.state != game.State.TITLE:
		push_error("Unrelated Android hardware keys must not act as Start")
		quit(1)
		return
	var music_touch := InputEventScreenTouch.new()
	music_touch.index = 0
	music_touch.position = Vector2(300, 28)
	music_touch.pressed = true
	game._input(music_touch)
	if game.state != game.State.TITLE:
		push_error("Touching the title music control must not act as Start")
		quit(1)
		return
	# On Web, PRESS START overlaps the START GAME control that appears on level
	# select. The opening touch and its synthetic mouse event must not leak into it.
	var title_touch := InputEventScreenTouch.new()
	title_touch.index = 0
	title_touch.position = Vector2(180, 558)
	title_touch.pressed = true
	game._input(title_touch)
	if game.state != game.State.LEVEL_SELECT or not game.level_select_pointer_guard:
		push_error("A title touch must show level select with its opening pointer guarded")
		quit(1)
		return
	game.primary_menu_action()
	if game.state != game.State.LEVEL_SELECT:
		push_error("The pointer that opened level select must not immediately start level 0")
		quit(1)
		return
	var title_synthetic_mouse := InputEventMouseButton.new()
	title_synthetic_mouse.position = title_touch.position
	title_synthetic_mouse.button_index = MOUSE_BUTTON_LEFT
	title_synthetic_mouse.pressed = true
	game._input(title_synthetic_mouse)
	game.primary_menu_action()
	if game.state != game.State.LEVEL_SELECT:
		push_error("The title touch's synthetic mouse click must not skip level select")
		quit(1)
		return
	var deliberate_level_touch := InputEventScreenTouch.new()
	deliberate_level_touch.index = 0
	deliberate_level_touch.position = Vector2(180, 558)
	deliberate_level_touch.pressed = true
	game._input(deliberate_level_touch)
	if game.level_select_pointer_guard:
		push_error("The next deliberate touch must immediately arm level-select controls")
		quit(1)
		return
	game.state = game.State.TITLE
	game.update_menu_controls()
	game.last_touch_event_msec = -1000000
	var title_start := InputEventKey.new()
	title_start.physical_keycode = KEY_SPACE
	title_start.pressed = true
	game._input(title_start)
	await process_frame
	if game.state != game.State.LEVEL_SELECT:
		push_error("The title Start action should open level selection")
		quit(1)
		return
	if not game.scores_button.visible or game.scores_button.position != Vector2(115, 324):
		push_error("Level selection must expose High Scores above the level panel")
		quit(1)
		return
	game.show_high_scores()
	if game.state != game.State.HIGH_SCORES or game.high_scores_return_state != game.State.LEVEL_SELECT:
		push_error("High Scores opened from level selection must remember its return screen")
		quit(1)
		return
	game.secondary_menu_action()
	if game.state != game.State.LEVEL_SELECT:
		push_error("Back from High Scores must return to level selection")
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
	game.first_gameplay_controls_pending = true
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	if game.state != game.State.PAUSED or not game.controls_visible or not game.controls_resume_gameplay:
		push_error("The first Start Game must show controls over a paused gameplay board")
		quit(1)
		return
	game.close_controls_screen()
	if game.state != game.State.PLAYING or game.controls_visible or game.first_gameplay_controls_pending:
		push_error("Dismissing first-game controls must resume the same game")
		quit(1)
		return
	if game.level != 5:
		push_error("Selected level should become the starting level")
		quit(1)
		return
	game.handle_android_back()
	if game.state != game.State.PAUSED:
		push_error("Android Back during gameplay must pause instead of closing")
		quit(1)
		return
	game.handle_android_back()
	if game.state != game.State.PLAYING:
		push_error("Android Back from pause must resume gameplay")
		quit(1)
		return
	var pause_touch := InputEventScreenTouch.new()
	pause_touch.index = 0
	pause_touch.position = Vector2(25, 18)
	pause_touch.pressed = true
	var rotation_before_pause: int = game.active.rotation
	game._input(pause_touch)
	if game.state != game.State.PLAYING or game.active.rotation != rotation_before_pause:
		push_error("The gameplay Pause control must not leak its touch to piece controls")
		quit(1)
		return
	game.toggle_pause()
	await process_frame
	if game.state != game.State.PAUSED or not game.start_button.visible or not game.retry_button.visible or not game.back_button.visible or not game.controls_button.visible:
		push_error("Pause must show Resume, Retry, Level Select, and How To Play actions")
		quit(1)
		return
	game.primary_menu_action()
	if game.state != game.State.PLAYING:
		push_error("Resume must return to active play")
		quit(1)
		return
	game.toggle_pause()
	game.secondary_menu_action()
	if game.state != game.State.LEVEL_SELECT:
		push_error("Level Select from pause must return to level selection")
		quit(1)
		return
	game.start_game()
	# Integration check for the complete six-line transaction: lock, pause, remove,
	# compact, score, then spawn. No next piece may appear in the middle.
	game.board.clear()
	var first_clear_row := GameConfig.BOARD_SIZE.y - 6
	for y in range(first_clear_row, GameConfig.BOARD_SIZE.y):
		for x in GameConfig.BOARD_SIZE.x:
			if x != 6:
				game.board.cells[y][x] = "J"
	game.board.cells[first_clear_row - 1][0] = "T"
	game.active = Hexomino.new("BAR")
	game.active.rotation = 1
	game.active.position = Vector2i(6, first_clear_row)
	var six_line_piece = game.active
	game.lock_piece(false)
	if game.state != game.State.CLEARING or game.clearing_rows != Array(range(first_clear_row, GameConfig.BOARD_SIZE.y)) or game.active != six_line_piece:
		push_error("A six-line clear must hold the locked piece and defer spawning until all rows resolve")
		quit(1)
		return
	if game.lock_flash_timer <= 0.0 or game.lock_flash_is_hard:
		push_error("A normal lock must start the restrained landing flash")
		quit(1)
		return
	game.handle_android_back()
	if not game.pause_after_clear:
		push_error("Android Back during a line-clear animation must queue pause")
		quit(1)
		return
	game.finish_line_clear()
	if game.state != game.State.PAUSED or game.lines != 6 or game.score != 3000 * (game.start_level + 1):
		push_error("A six-line clear must remove six rows and apply its score exactly once before play resumes")
		quit(1)
		return
	game.toggle_pause()
	if game.cat_crowd_count() != 1 or game.golden_cat_count() != 1 or game.cat_crowd_jump_timer <= 0.0:
		push_error("A six-line clear must add one golden cat instead of ordinary cats and make the crowd jump")
		quit(1)
		return
	if not game.board.full_rows().is_empty() or game.board.cells[-1][0] != "T" or game.active == six_line_piece:
		push_error("Six-line compaction must preserve surviving blocks and spawn the next piece afterward")
		quit(1)
		return
	game.retry_game()
	game.hard_drop()
	await process_frame
	if game.hard_drop_fx_timer <= 0.0 or game.hard_drop_landed_cells.size() != 6 or game.hard_drop_shock_pixels.size() != 24:
		push_error("Hard drop should begin the visual trail and impact overlay")
		quit(1)
		return
	if game.lock_flash_timer <= 0.0 or not game.lock_flash_is_hard or game.lock_flash_duration != game.HARD_LOCK_FLASH_SECONDS:
		push_error("Hard drop must start the stronger multi-pulse lock flash")
		quit(1)
		return
	game.retry_game()
	if game.state != game.State.PLAYING or game.score != 0 or game.lines != 0 or game.level != 5 or game.cat_crowd_count() != 0 or game.golden_cat_count() != 0:
		push_error("Retry should immediately reset the current run at the selected starting level")
		quit(1)
		return
	game.score = 4321
	game.high_scores.clear()
	for high_score_rank in SaveSystem.MAX_HIGH_SCORES:
		game.high_scores.append({"name": "CAT", "score": 999999 - high_score_rank, "level": 9, "lines": 99})
	game.finish_run()
	if game.state != game.State.ENDING or not is_zero_approx(game.ending_timer) or game.audio.current_music != "ending":
		push_error("Top-out should enter the Stargazer ending before any result menu")
		quit(1)
		return
	game._process(60.0)
	if game.state != game.State.ENDING:
		push_error("The Stargazer ending must remain open until the player continues")
		quit(1)
		return
	var ending_confirm := InputEventKey.new()
	ending_confirm.physical_keycode = KEY_ENTER
	ending_confirm.pressed = true
	game.ending_timer = game.ENDING_SKIP_DELAY - 0.1
	game._input(ending_confirm)
	if game.state != game.State.ENDING:
		push_error("The ending must ignore accidental skip input during its opening fade")
		quit(1)
		return
	game.ending_timer = game.ENDING_SKIP_DELAY
	game._input(ending_confirm)
	if game.state != game.State.GAME_OVER or game.audio.current_music != "":
		push_error("A non-qualifying score should continue from the ending to Game Over")
		quit(1)
		return
	game.retry_game()
	# Android may deliver a release or begin the next hold while the line-clear
	# animation owns the game state. Neither case may poison the next piece.
	game.state = game.State.CLEARING
	game.touch_active = true
	game.touch_index = 0
	game.touch_gesture = game.TouchGesture.VERTICAL
	var clear_release := InputEventScreenTouch.new()
	clear_release.index = 0
	clear_release.position = Vector2(180, 300)
	clear_release.pressed = false
	game._input(clear_release)
	if game.touch_active:
		push_error("A finger released during a line clear must not remain latched")
		quit(1)
		return
	var clear_press := InputEventScreenTouch.new()
	clear_press.index = 0
	clear_press.position = Vector2(180, 300)
	clear_press.pressed = true
	game._input(clear_press)
	var clear_drag := InputEventScreenDrag.new()
	clear_drag.index = 0
	clear_drag.position = Vector2(190, 300)
	game._input(clear_drag)
	game.state = game.State.PLAYING
	var post_clear_x: int = game.active.position.x
	var post_clear_drag := InputEventScreenDrag.new()
	post_clear_drag.index = 0
	post_clear_drag.position = Vector2(216, 300)
	game._input(post_clear_drag)
	if game.active.position.x != post_clear_x + 1:
		push_error("A hold begun during line clear must move the next piece without another lift")
		quit(1)
		return
	var post_clear_release := InputEventScreenTouch.new()
	post_clear_release.index = 0
	post_clear_release.position = Vector2(216, 300)
	post_clear_release.pressed = false
	game._input(post_clear_release)
	# Android can synthesize a mouse click immediately after a touch. A single
	# tap must still rotate exactly once.
	game.active = Hexomino.new("T")
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
	# Web touch-to-mouse synthesis may be delayed by a busy frame. It must not
	# rotate a later piece after the old 500 ms suppression window.
	var rotation_after_touch: int = game.active.rotation
	game.last_touch_event_msec -= 700
	game._input(emulated_mouse)
	if game.active.rotation != rotation_after_touch:
		push_error("A delayed Web synthetic mouse click must not rotate the next piece")
		quit(1)
		return
	# A small attempted swipe can remain below the axis-lock threshold. It is not
	# a deliberate stationary tap and must not be reinterpreted as rotation.
	game.active = Hexomino.new("T")
	var short_swipe_press := InputEventScreenTouch.new()
	short_swipe_press.index = 0
	short_swipe_press.position = Vector2(180, 300)
	short_swipe_press.pressed = true
	game._input(short_swipe_press)
	var short_swipe_drag := InputEventScreenDrag.new()
	short_swipe_drag.index = 0
	short_swipe_drag.position = Vector2(188, 300)
	game._input(short_swipe_drag)
	var short_swipe_release := InputEventScreenTouch.new()
	short_swipe_release.index = 0
	short_swipe_release.position = short_swipe_drag.position
	short_swipe_release.pressed = false
	game._input(short_swipe_release)
	if game.active.rotation != 0:
		push_error("A short attempted swipe must not rotate the active piece")
		quit(1)
		return
	# Dragging should move during the drag instead of batching movement at release.
	game.active = Hexomino.new("T")
	var drag_start_x: int = game.active.position.x
	var drag_press := InputEventScreenTouch.new()
	drag_press.index = 0
	drag_press.position = Vector2(100, 300)
	drag_press.pressed = true
	game._input(drag_press)
	var horizontal_drag := InputEventScreenDrag.new()
	horizontal_drag.index = 0
	horizontal_drag.position = Vector2(100 + GameConfig.CELL_SIZE, 300)
	game._input(horizontal_drag)
	if game.active.position.x != drag_start_x + 1 or game.active.rotation != 0:
		push_error("Horizontal touch drag should move one cell immediately without rotating")
		quit(1)
		return
	var drag_release := InputEventScreenTouch.new()
	drag_release.index = 0
	drag_release.position = Vector2(100 + GameConfig.CELL_SIZE, 300)
	drag_release.pressed = false
	game._input(drag_release)
	if game.active.position.x != drag_start_x + 1 or game.active.rotation != 0:
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
	var down_release := InputEventScreenTouch.new()
	down_release.index = 0
	down_release.position = Vector2(180, 263)
	down_release.pressed = false
	# Make this explicitly a slow drag; it must not become a hard drop.
	game.touch_press_msec -= game.TOUCH_SWIPE_DROP_MAX_MS + 1
	game._input(down_release)
	if game.active.position.y != 1:
		push_error("A slow downward drag should remain a soft drop on release")
		quit(1)
		return
	var piece_before_swipe = game.active
	var swipe_press := InputEventScreenTouch.new()
	swipe_press.index = 0
	swipe_press.position = Vector2(180, 250)
	swipe_press.pressed = true
	game._input(swipe_press)
	var swipe_release := InputEventScreenTouch.new()
	swipe_release.index = 0
	swipe_release.position = Vector2(180, 300)
	swipe_release.pressed = false
	game._input(swipe_release)
	if game.active == piece_before_swipe or game.hard_drop_fx_timer <= 0.0:
		push_error("A quick downward swipe should hard-drop and spawn the next piece")
		quit(1)
		return
	# Upward movement is neutral and must not trap the remainder of a held-finger
	# gesture. Horizontal movement should work immediately afterward.
	game.active = Hexomino.new("T")
	var neutral_start_position: Vector2i = game.active.position
	var neutral_up_press := InputEventScreenTouch.new()
	neutral_up_press.index = 0
	neutral_up_press.position = Vector2(180, 300)
	neutral_up_press.pressed = true
	game._input(neutral_up_press)
	var neutral_up_drag := InputEventScreenDrag.new()
	neutral_up_drag.index = 0
	neutral_up_drag.position = Vector2(180, 270)
	game._input(neutral_up_drag)
	if game.active.position != neutral_start_position or game.active.rotation != 0:
		push_error("Upward touch movement should have no gameplay action")
		quit(1)
		return
	var after_up_horizontal := InputEventScreenDrag.new()
	after_up_horizontal.index = 0
	after_up_horizontal.position = Vector2(180 + GameConfig.CELL_SIZE, 270)
	game._input(after_up_horizontal)
	if game.active.position.x != neutral_start_position.x + 1:
		push_error("Upward movement should not block later horizontal movement on the same touch")
		quit(1)
		return
	var neutral_up_release := InputEventScreenTouch.new()
	neutral_up_release.index = 0
	neutral_up_release.position = after_up_horizontal.position
	neutral_up_release.pressed = false
	game._input(neutral_up_release)
	if game.active.rotation != 0:
		push_error("Releasing after neutral-up then horizontal movement should not rotate")
		quit(1)
		return
	# A player must be able to position horizontally and then turn the same
	# held-finger gesture downward for a decisive hard drop.
	game.active = Hexomino.new("T")
	var combined_piece = game.active
	var combined_start_x: int = game.active.position.x
	var combined_press := InputEventScreenTouch.new()
	combined_press.index = 0
	combined_press.position = Vector2(100, 300)
	combined_press.pressed = true
	game._input(combined_press)
	var combined_horizontal := InputEventScreenDrag.new()
	combined_horizontal.index = 0
	combined_horizontal.position = Vector2(100 + GameConfig.CELL_SIZE, 300)
	game._input(combined_horizontal)
	if game.active.position.x != combined_start_x + 1:
		push_error("Combined gesture should first position the piece horizontally")
		quit(1)
		return
	var combined_turn_down := InputEventScreenDrag.new()
	combined_turn_down.index = 0
	combined_turn_down.position = Vector2(100 + GameConfig.CELL_SIZE, 320)
	game._input(combined_turn_down)
	if game.active != combined_piece:
		push_error("Initial downward turn should soft-drop before it becomes decisive")
		quit(1)
		return
	var combined_swipe_down := InputEventScreenDrag.new()
	combined_swipe_down.index = 0
	combined_swipe_down.position = Vector2(100 + GameConfig.CELL_SIZE, 350)
	game._input(combined_swipe_down)
	if game.active == combined_piece:
		push_error("Horizontal movement followed by a decisive down swipe should hard-drop without lifting")
		quit(1)
		return
	var combined_release := InputEventScreenTouch.new()
	combined_release.index = 0
	combined_release.position = combined_swipe_down.position
	combined_release.pressed = false
	game._input(combined_release)
	# Reversing horizontal direction makes the rest of that contact ineligible
	# for hard drop, while retaining unrestricted side movement and soft drop.
	game.active = Hexomino.new("T")
	var reversal_piece = game.active
	var reversal_press := InputEventScreenTouch.new()
	reversal_press.index = 0
	reversal_press.position = Vector2(150, 280)
	reversal_press.pressed = true
	game._input(reversal_press)
	var reversal_right := InputEventScreenDrag.new()
	reversal_right.index = 0
	reversal_right.position = Vector2(150 + GameConfig.CELL_SIZE, 280)
	game._input(reversal_right)
	var reversal_left := InputEventScreenDrag.new()
	reversal_left.index = 0
	reversal_left.position = Vector2(150 - GameConfig.CELL_SIZE, 280)
	game._input(reversal_left)
	if not game.touch_horizontal_reversed:
		push_error("Changing horizontal direction should disable hard drop for that touch")
		quit(1)
		return
	var reversal_turn_down := InputEventScreenDrag.new()
	reversal_turn_down.index = 0
	reversal_turn_down.position = Vector2(150 - GameConfig.CELL_SIZE, 300)
	game._input(reversal_turn_down)
	var reversal_fast_down := InputEventScreenDrag.new()
	reversal_fast_down.index = 0
	reversal_fast_down.position = Vector2(150 - GameConfig.CELL_SIZE, 330)
	game._input(reversal_fast_down)
	if game.active != reversal_piece or game.active.position.y <= 0:
		push_error("Down swipe after a horizontal reversal should soft-drop rather than hard-drop")
		quit(1)
		return
	var reversal_release := InputEventScreenTouch.new()
	reversal_release.index = 0
	reversal_release.position = reversal_fast_down.position
	reversal_release.pressed = false
	game._input(reversal_release)
	var reset_piece = game.active
	var reset_press := InputEventScreenTouch.new()
	reset_press.index = 0
	reset_press.position = Vector2(180, 250)
	reset_press.pressed = true
	game._input(reset_press)
	var reset_swipe := InputEventScreenTouch.new()
	reset_swipe.index = 0
	reset_swipe.position = Vector2(180, 300)
	reset_swipe.pressed = false
	game._input(reset_swipe)
	if game.active == reset_piece:
		push_error("Lifting the finger should restore hard-drop eligibility")
		quit(1)
		return
	print("PASS: Space starts the game")
	quit(0)
