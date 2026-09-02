extends Control

enum State { TITLE, LEVEL_SELECT, PLAYING, CLEARING, PAUSED, ENDING, GAME_OVER, NAME_ENTRY, HIGH_SCORES }
enum TouchGesture { PENDING, HORIZONTAL, VERTICAL, HARD_DROP, CONTROLS }
enum GameMode { STANDARD, FLOWING }

const PANEL := Color("1d1b1a")
const CREAM := Color("efe2be")
const WOOD := Color("68462f")
const WOOD_LIGHT := Color("a7754a")
const START_BUTTON_RECT := Rect2(90, 538, 180, 42)
const MENU_BUTTON_SIZE := Vector2(180, 38)
const LEVEL_GRID_ORIGIN := Vector2(58, 462)
const LEVEL_BUTTON_SIZE := Vector2(44, 32)
const LEVEL_BUTTON_GAP := Vector2(6, 6)
const MOUSE_AFTER_TOUCH_SUPPRESS_MS := 1500
const TOUCH_AXIS_LOCK_PIXELS := 10.0
const TOUCH_TAP_MAX_PIXELS := 5.0
const TOUCH_HORIZONTAL_STEP_PIXELS := 22.0
const TOUCH_VERTICAL_STEP_PIXELS := 12.0
const TOUCH_AXIS_CHANGE_PIXELS := 18.0
const TOUCH_SWIPE_DROP_MIN_PIXELS := 48.0
const TOUCH_SWIPE_DROP_MAX_MS := 240
const NORMAL_LOCK_FLASH_SECONDS := 0.24
const HARD_LOCK_FLASH_SECONDS := 0.40
const ENDING_SKIP_DELAY := 0.85
const ENDING_CAT_FRAME_SECONDS := 0.72
const ENDING_CAT_SEQUENCE := [0, 1, 2, 5, 4, 3, 4, 5, 2, 1]
const ENDING_NEW_STAR_POSITION := Vector2(94, 212)
const LANTERN_ENDING_SCORE := 10000
const LANTERN_RISING_SPAWN_SECONDS := 0.22
const LANTERN_INITIAL_RISING_COUNT := 4
const LANTERN_AMBIENT_POSITIONS := [
	Vector2(153, 151),
	Vector2(193, 128),
	Vector2(234, 157),
	Vector2(278, 140),
	Vector2(318, 169),
	Vector2(143, 202),
	Vector2(181, 229),
	Vector2(218, 191),
	Vector2(258, 216),
	Vector2(300, 238),
	Vector2(239, 250),
	Vector2(326, 205),
]
const CONTROLS_PANEL_RECT := Rect2(24, 70, 312, 500)
const CAT_CROWD_JUMP_SECONDS := 0.62
const CAT_CROWD_SIZE := Vector2(24, 29)
const CAT_CROWD_MIN := Vector2(324, 116)
const CAT_CROWD_MAX := Vector2(334, 594)

var board := GameBoard.new()
var active: Polyomino
var next_kind := ""
var state := State.TITLE
var score := 0
var lines := 0
var level := 0
var start_level := 0
var game_mode := GameMode.STANDARD
var line_clear_seconds := GameConfig.LINE_CLEAR_SECONDS
var high_score := 0
var high_scores: Array[Dictionary] = []
var high_scores_return_state := State.TITLE
var gravity_accumulator := 0.0
var soft_drop_accumulator := 0.0
var lock_timer := 0.0
var clear_timer := 0.0
var clearing_rows: Array[int] = []
var line_clear_shards: Array[Dictionary] = []
var line_shard_rng := RandomNumberGenerator.new()
var repeat_direction := 0
var repeat_timer := 0.0
var touch_start := Vector2.ZERO
var touch_last := Vector2.ZERO
var touch_active := false
var touch_index := -1
var last_touch_event_msec := -1000000
var level_select_pointer_guard := false
var level_select_guard_from_touch := false
var touch_press_msec := 0
var touch_gesture := TouchGesture.PENDING
var touch_drag_remainder := Vector2.ZERO
var touch_max_travel := 0.0
var touch_down_transition := 0.0
var touch_transition_start_msec := 0
var touch_vertical_start_y := 0.0
var touch_vertical_start_msec := 0
var touch_horizontal_direction := 0
var touch_horizontal_reversed := false
var cat_happy_timer := 0.0
var cat_frame_timer := 0.0
var cat_frame := 0
var cat_crowd_jump_timer := 0.0
var cat_crowd_positions: Array[Vector2] = []
var cat_crowd_golden: Array[bool] = []
var cat_crowd_rng := RandomNumberGenerator.new()
var cat_crowd_fx_time := 0.0
var hard_drop_fx_timer := 0.0
var hard_drop_start_cells: Array = []
var hard_drop_landed_cells: Array = []
var hard_drop_shock_pixels: Array = []
var hard_drop_kind := ""
var lock_flash_timer := 0.0
var lock_flash_duration := 0.0
var lock_flash_cells: Array = []
var lock_flash_kind := ""
var lock_flash_is_hard := false
var ending_timer := 0.0
var ending_preview_mode := false
var ending_preview_return_state := State.TITLE
var ending_preview_saved_score := 0
var controls_visible := false
var first_gameplay_controls_pending := false
var controls_resume_gameplay := false
var pause_after_clear := false
var flow_rise_accumulator := 0.0
var flow_pattern_index := 0
var flow_cascade_depth := 0
var flow_falling_cells: Array = []
var flow_falling_kind := ""
var piece_randomizer := PieceRandomizer.new()
var audio: AudioSystem
var background: Texture2D
var title_background: Texture2D
var level_select_background: Texture2D
var board_frame: Texture2D
var panel_textures: Dictionary = {}
var idle_textures: Array[Texture2D] = []
var happy_textures: Array[Texture2D] = []
var golden_cat_texture: Texture2D
var tile_textures: Dictionary = {}
var ghost_texture: Texture2D
var line_clear_frames: Array[Texture2D] = []
var ending_background: Texture2D
var ending_cat_sheet: Texture2D
var ending_score_plaque: Texture2D
var lantern_texture: Texture2D
var start_button: Button
var level_buttons: Array[Button] = []
var level_select_label: Label
var mode_buttons: Array[Button] = []
var music_button: Button
var scores_button: Button
var back_button: Button
var pause_button: Button
var retry_button: Button
var controls_button: Button
var controls_close_button: Button
var name_entry: LineEdit
var name_submit_button: Button
var light_fx_layer: Control

func _ready() -> void:
	setup_input_map()
	audio = AudioSystem.new()
	add_child(audio)
	high_scores = SaveSystem.load_high_scores()
	cat_crowd_rng.randomize()
	line_shard_rng.randomize()
	high_score = int(high_scores[0].score) if not high_scores.is_empty() else 0
	background = load("res://assets/backgrounds/cat_room.png")
	title_background = load("res://assets/source/titlev2.png")
	level_select_background = load("res://assets/source/room_background.png")
	board_frame = load("res://assets/source/framev2.png")
	ending_background = load("res://assets/endings/stargazer/background.png")
	ending_cat_sheet = load("res://assets/endings/stargazer/cat_sheet_aligned.png")
	ending_score_plaque = load("res://assets/endings/stargazer/score_plaque.png")
	lantern_texture = load("res://assets/endings/lantern.png")
	panel_textures = {
		"SCORE": load("res://assets/blocks/score.png"),
		"LEVEL": load("res://assets/blocks/level.png"),
		"LINES": load("res://assets/blocks/lines.png"),
		"NEXT": load("res://assets/blocks/next.png"),
	}
	for i in range(1, 5):
		idle_textures.append(load("res://assets/cat/idle_%02d.png" % i))
		happy_textures.append(load("res://assets/cat/happy_%02d.png" % i))
	golden_cat_texture = load("res://assets/cat/golden_01.png")
	load_block_textures()
	create_start_button()
	create_level_selector()
	create_music_button()
	create_score_controls()
	create_pause_controls()
	create_controls_screen()
	create_light_fx_layer()
	audio.set_music_enabled(bool(SaveSystem.load_setting("music_enabled", true)))
	# V1 uses a new key because the early draft displayed this on the title. The
	# release behavior waits until the player can see their first gameplay board.
	first_gameplay_controls_pending = not bool(SaveSystem.load_setting("gameplay_controls_seen_v1", false))
	audio.play_title_music()
	update_menu_controls()
	set_process(true)
	queue_redraw()
	if light_fx_layer:
		light_fx_layer.queue_redraw()

func create_light_fx_layer() -> void:
	light_fx_layer = Control.new()
	light_fx_layer.set_script(load("res://scripts/light_fx_layer.gd"))
	light_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	light_fx_layer.set("game", self)
	add_child(light_fx_layer)

func load_block_textures() -> void:
	for kind: String in GameConfig.PIECE_KINDS:
		var source_kind: String = GameConfig.TILE_SOURCE_KIND[kind]
		var path := "res://assets/blocks/wood/tile_%s.png" % source_kind.to_lower()
		if ResourceLoader.exists(path):
			tile_textures[kind] = load(path)
	ghost_texture = load("res://assets/blocks/processed/ghost.png")
	for i in range(1, 7):
		line_clear_frames.append(load("res://assets/fx/line_clear/frame_%02d.png" % i))

func create_start_button() -> void:
	start_button = Button.new()
	start_button.position = START_BUTTON_RECT.position
	start_button.size = START_BUTTON_RECT.size
	start_button.text = "START GAME"
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.add_theme_font_size_override("font_size", 17)
	style_menu_button(start_button)
	start_button.pressed.connect(primary_menu_action)
	add_child(start_button)
	start_button.call_deferred("grab_focus")

func create_level_selector() -> void:
	level_select_label = Label.new()
	level_select_label.position = Vector2(58, 436)
	level_select_label.size = Vector2(244, 26)
	level_select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_select_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_select_label.add_theme_font_size_override("font_size", 14)
	level_select_label.add_theme_color_override("font_color", CREAM)
	add_child(level_select_label)
	for mode_value in [GameMode.STANDARD, GameMode.FLOWING]:
		var mode_button := Button.new()
		mode_button.position = Vector2(58 + mode_buttons.size() * 128, 402)
		mode_button.size = Vector2(116, 30)
		mode_button.text = "STANDARD" if mode_value == GameMode.STANDARD else "FLOWING"
		mode_button.toggle_mode = true
		mode_button.focus_mode = Control.FOCUS_ALL
		mode_button.add_theme_font_size_override("font_size", 12)
		style_menu_button(mode_button)
		mode_button.pressed.connect(set_game_mode.bind(mode_value))
		add_child(mode_button)
		mode_buttons.append(mode_button)
	for level_number in range(GameConfig.MAX_LEVEL + 1):
		var button := Button.new()
		var column := level_number % 5
		var row := level_number / 5
		button.position = LEVEL_GRID_ORIGIN + Vector2(column, row) * (LEVEL_BUTTON_SIZE + LEVEL_BUTTON_GAP)
		button.size = LEVEL_BUTTON_SIZE
		button.text = str(level_number)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 15)
		style_menu_button(button)
		button.pressed.connect(set_start_level.bind(level_number))
		add_child(button)
		level_buttons.append(button)
	set_start_level(start_level, false)
	set_game_mode(game_mode, false)

func style_menu_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("30271f")
	normal.border_color = Color("b8935d")
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 3
	normal.corner_radius_top_right = 3
	normal.corner_radius_bottom_left = 3
	normal.corner_radius_bottom_right = 3
	var hover := normal.duplicate()
	hover.bg_color = Color("55412d")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("b07b37")
	pressed.border_color = Color("f3d48d")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_pressed_color", Color("fff0bd"))

func adjust_start_level(amount: int) -> void:
	set_start_level(start_level + amount)

func set_start_level(value: int, play_sound := true) -> void:
	var next_level := clampi(value, 0, GameConfig.MAX_LEVEL)
	var changed := next_level != start_level
	start_level = next_level
	if level_select_label:
		level_select_label.text = "SELECT STARTING LEVEL  •  %d" % start_level
	for i in level_buttons.size():
		level_buttons[i].set_pressed_no_signal(i == start_level)
	if changed and play_sound and audio:
		audio.play_ui_select()

func set_game_mode(value: int, play_sound := true) -> void:
	var next_mode := GameMode.FLOWING if value == GameMode.FLOWING else GameMode.STANDARD
	var changed := next_mode != game_mode
	game_mode = next_mode
	for i in mode_buttons.size():
		mode_buttons[i].set_pressed_no_signal(i == game_mode)
	if changed and play_sound and audio:
		audio.play_ui_select()
	queue_redraw()

func set_line_clear_seconds(value: float) -> void:
	line_clear_seconds = clampf(value, 0.08, 0.40)

func create_music_button() -> void:
	music_button = Button.new()
	music_button.position = Vector2(250, 18)
	music_button.size = Vector2(98, 23)
	music_button.focus_mode = Control.FOCUS_NONE
	music_button.add_theme_font_size_override("font_size", 11)
	style_menu_button(music_button)
	music_button.pressed.connect(toggle_music)
	add_child(music_button)
	update_music_button()

func create_score_controls() -> void:
	scores_button = Button.new()
	scores_button.size = MENU_BUTTON_SIZE
	scores_button.text = "HIGH SCORES"
	scores_button.focus_mode = Control.FOCUS_ALL
	style_menu_button(scores_button)
	scores_button.pressed.connect(show_high_scores)
	add_child(scores_button)

	back_button = Button.new()
	back_button.size = MENU_BUTTON_SIZE
	back_button.focus_mode = Control.FOCUS_ALL
	style_menu_button(back_button)
	back_button.pressed.connect(secondary_menu_action)
	add_child(back_button)

	name_entry = LineEdit.new()
	name_entry.position = Vector2(80, 306)
	name_entry.size = Vector2(200, 42)
	name_entry.max_length = 10
	name_entry.placeholder_text = "YOUR NAME"
	name_entry.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_entry.add_theme_font_size_override("font_size", 18)
	name_entry.text_submitted.connect(func(_value: String) -> void: submit_high_score())
	add_child(name_entry)

	name_submit_button = Button.new()
	name_submit_button.position = Vector2(90, 364)
	name_submit_button.size = MENU_BUTTON_SIZE
	name_submit_button.text = "SAVE SCORE"
	name_submit_button.focus_mode = Control.FOCUS_ALL
	style_menu_button(name_submit_button)
	name_submit_button.pressed.connect(submit_high_score)
	add_child(name_submit_button)

func create_pause_controls() -> void:
	pause_button = Button.new()
	pause_button.position = Vector2(6, 5)
	pause_button.size = Vector2(42, 29)
	pause_button.text = "II"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.add_theme_font_size_override("font_size", 16)
	style_menu_button(pause_button)
	pause_button.pressed.connect(toggle_pause)
	add_child(pause_button)

	retry_button = Button.new()
	retry_button.size = MENU_BUTTON_SIZE
	retry_button.text = "RETRY"
	retry_button.focus_mode = Control.FOCUS_ALL
	style_menu_button(retry_button)
	retry_button.pressed.connect(retry_game)
	add_child(retry_button)

func create_controls_screen() -> void:
	controls_button = Button.new()
	controls_button.size = MENU_BUTTON_SIZE
	controls_button.text = "HOW TO PLAY"
	controls_button.focus_mode = Control.FOCUS_ALL
	style_menu_button(controls_button)
	controls_button.pressed.connect(open_controls_screen)
	add_child(controls_button)

	controls_close_button = Button.new()
	controls_close_button.position = Vector2(90, 515)
	controls_close_button.size = MENU_BUTTON_SIZE
	controls_close_button.text = "GOT IT"
	controls_close_button.focus_mode = Control.FOCUS_ALL
	style_menu_button(controls_close_button)
	controls_close_button.pressed.connect(close_controls_screen)
	add_child(controls_close_button)

func open_controls_screen() -> void:
	if state not in [State.TITLE, State.PAUSED]:
		return
	audio.play_ui_select()
	controls_resume_gameplay = false
	controls_visible = true
	update_menu_controls()
	controls_close_button.call_deferred("grab_focus")
	queue_redraw()

func close_controls_screen() -> void:
	if not controls_visible:
		return
	controls_visible = false
	first_gameplay_controls_pending = false
	SaveSystem.save_setting("gameplay_controls_seen_v1", true)
	if controls_resume_gameplay and state == State.PAUSED:
		controls_resume_gameplay = false
		state = State.PLAYING
		audio.set_gameplay_paused(false)
	audio.play_ui_confirm()
	update_menu_controls()
	queue_redraw()

func toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
	elif state == State.PAUSED:
		state = State.PLAYING
	else:
		return
	audio.set_gameplay_paused(state == State.PAUSED)
	audio.play_pause(state == State.PAUSED)
	update_menu_controls()
	queue_redraw()

func show_high_scores() -> void:
	if state not in [State.TITLE, State.LEVEL_SELECT, State.GAME_OVER, State.NAME_ENTRY]:
		return
	high_scores_return_state = State.GAME_OVER if state == State.NAME_ENTRY else state
	audio.play_ui_select()
	name_entry.release_focus()
	state = State.HIGH_SCORES
	queue_redraw()

func secondary_menu_action() -> void:
	audio.play_ui_cancel()
	if state == State.LEVEL_SELECT:
		state = State.TITLE
		queue_redraw()
	elif state in [State.PAUSED, State.GAME_OVER]:
		open_level_select(true)
	elif state == State.HIGH_SCORES:
		state = high_scores_return_state
		if state in [State.TITLE, State.LEVEL_SELECT]:
			audio.play_title_music()
		queue_redraw()

func submit_high_score() -> void:
	if state != State.NAME_ENTRY:
		return
	var player_name := SaveSystem.sanitize_player_name(name_entry.text)
	SaveSystem.save_setting("player_name", player_name)
	high_scores = SaveSystem.add_high_score(player_name, score, level, lines)
	high_score = int(high_scores[0].score) if not high_scores.is_empty() else 0
	audio.play_name_saved()
	name_entry.release_focus()
	high_scores_return_state = State.GAME_OVER
	state = State.HIGH_SCORES
	queue_redraw()

func toggle_music() -> void:
	audio.play_ui_select()
	audio.set_music_enabled(not audio.music_enabled)
	SaveSystem.save_setting("music_enabled", audio.music_enabled)
	update_music_button()

func update_music_button() -> void:
	if music_button:
		music_button.text = "MUSIC %s" % ("ON" if audio == null or audio.music_enabled else "OFF")

func setup_input_map() -> void:
	bind_keys("move_left", [KEY_A, KEY_LEFT])
	bind_keys("move_right", [KEY_D, KEY_RIGHT])
	bind_keys("soft_drop", [KEY_S, KEY_DOWN])
	bind_keys("hard_drop", [KEY_SPACE])
	bind_keys("rotate", [KEY_X, KEY_UP])
	bind_keys("pause", [KEY_P, KEY_ESCAPE])
	bind_keys("retry", [KEY_R])
	bind_keys("toggle_music", [KEY_M])
	bind_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	bind_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	bind_joy_button("soft_drop", JOY_BUTTON_DPAD_DOWN)
	bind_joy_button("hard_drop", JOY_BUTTON_A)
	bind_joy_button("rotate", JOY_BUTTON_B)
	bind_joy_button("pause", JOY_BUTTON_START)

func bind_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)

func bind_joy_button(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _process(delta: float) -> void:
	update_menu_controls()
	update_line_clear_shards(delta)
	if hard_drop_fx_timer > 0.0:
		hard_drop_fx_timer = maxf(0.0, hard_drop_fx_timer - delta)
	if lock_flash_timer > 0.0:
		lock_flash_timer = maxf(0.0, lock_flash_timer - delta)
	if light_fx_layer:
		light_fx_layer.queue_redraw()
	cat_frame_timer += delta
	if cat_frame_timer >= 0.22:
		cat_frame_timer = 0.0
		cat_frame = (cat_frame + 1) % 4
	if cat_happy_timer > 0.0:
		cat_happy_timer -= delta
	if cat_crowd_jump_timer > 0.0:
		cat_crowd_jump_timer = maxf(0.0, cat_crowd_jump_timer - delta)
	cat_crowd_fx_time += delta

	if state == State.ENDING:
		ending_timer += delta
	elif state == State.CLEARING:
		clear_timer -= delta
		if clear_timer <= 0.0:
			finish_line_clear()
	elif state == State.PLAYING:
		if game_mode == GameMode.FLOWING:
			flow_rise_accumulator += delta
			var flow_interval := GameConfig.flow_rise_seconds(level)
			while flow_rise_accumulator >= flow_interval:
				flow_rise_accumulator -= flow_interval
				if not advance_flow_floor():
					finish_run()
					return
		process_keyboard_repeat(delta)
		if board.fits(active, active.position + Vector2i.DOWN, active.rotation):
			lock_timer = 0.0
		else:
			lock_timer += delta
			if lock_timer >= GameConfig.LOCK_DELAY_SECONDS:
				lock_piece()
				queue_redraw()
				return
		if Input.is_action_pressed("soft_drop"):
			# Soft drop owns its own clock. Never reinterpret stored gravity as fast-drop steps.
			gravity_accumulator = 0.0
			soft_drop_accumulator += delta
			if Input.is_action_just_pressed("soft_drop"):
				soft_drop_accumulator = GameConfig.SOFT_DROP_SECONDS
			while soft_drop_accumulator >= GameConfig.SOFT_DROP_SECONDS:
				soft_drop_accumulator -= GameConfig.SOFT_DROP_SECONDS
				if try_move(Vector2i.DOWN):
					score += 1
					audio.play_soft_drop()
				else:
					soft_drop_accumulator = 0.0
					break
		else:
			soft_drop_accumulator = 0.0
			gravity_accumulator += delta
			var interval := GameConfig.gravity_seconds(level)
			while gravity_accumulator >= interval:
				gravity_accumulator -= interval
				if not try_move(Vector2i.DOWN):
					gravity_accumulator = 0.0
					break
	queue_redraw()

func update_menu_controls() -> void:
	var on_title := state == State.TITLE
	var on_level_select := state == State.LEVEL_SELECT
	var on_game_over := state == State.GAME_OVER
	var on_paused := state == State.PAUSED
	var on_name_entry := state == State.NAME_ENTRY
	var on_high_scores := state == State.HIGH_SCORES
	level_select_label.visible = on_level_select
	for button in level_buttons:
		button.visible = on_level_select
	for button in mode_buttons:
		button.visible = on_level_select
	start_button.visible = on_level_select or on_game_over or on_paused
	music_button.visible = state not in [State.CLEARING, State.ENDING, State.NAME_ENTRY]
	music_button.position = Vector2(250, 18) if state in [State.TITLE, State.LEVEL_SELECT, State.GAME_OVER, State.HIGH_SCORES] else Vector2(154, 55)
	scores_button.visible = on_level_select or on_game_over
	back_button.visible = on_level_select or on_game_over or on_high_scores or on_paused
	pause_button.visible = state == State.PLAYING
	retry_button.visible = on_paused
	controls_button.visible = on_paused
	controls_close_button.visible = controls_visible
	name_entry.visible = on_name_entry
	name_submit_button.visible = on_name_entry
	if on_paused:
		start_button.position = Vector2(90, 302)
		start_button.text = "RESUME"
		retry_button.position = Vector2(90, 348)
		back_button.position = Vector2(90, 394)
		back_button.size = MENU_BUTTON_SIZE
		back_button.text = "LEVEL SELECT"
		controls_button.position = Vector2(90, 440)
	elif on_level_select:
		start_button.position = START_BUTTON_RECT.position
		start_button.text = "START GAME"
		scores_button.position = Vector2(115, 324)
		scores_button.size = Vector2(130, 34)
		back_button.position = Vector2(115, 596)
		back_button.size = Vector2(130, 34)
		back_button.text = "BACK"
	elif on_game_over:
		scores_button.size = MENU_BUTTON_SIZE
		back_button.size = MENU_BUTTON_SIZE
		start_button.position = Vector2(90, 370)
		start_button.text = "RETRY"
		scores_button.position = Vector2(90, 416)
		back_button.position = Vector2(90, 462)
		back_button.text = "LEVEL SELECT"
	elif on_high_scores:
		back_button.size = MENU_BUTTON_SIZE
		back_button.position = Vector2(90, 548)
		back_button.text = "BACK"
	if controls_visible:
		for control: Control in [level_select_label, start_button, music_button, scores_button, back_button, pause_button, retry_button, controls_button, name_entry, name_submit_button]:
			control.visible = false
		for button in level_buttons:
			button.visible = false
		for button in mode_buttons:
			button.visible = false
		controls_close_button.visible = true

func _input(event: InputEvent) -> void:
	# Remember touch activity before routing by game state. Godot may emit a
	# synthetic mouse click immediately afterward, including across menus.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		last_touch_event_msec = Time.get_ticks_msec()
	update_level_select_pointer_guard(event)
	if controls_visible:
		if is_confirm_input(event) \
			or (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and should_handle_pointer_mouse()):
			close_controls_screen()
			get_viewport().set_input_as_handled()
		return
	if handle_debug_ending_shortcut(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_music"):
		toggle_music()
		return
	if state == State.CLEARING and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		handle_touch_during_clear(event)
		return
	if state == State.ENDING:
		if ending_timer >= ENDING_SKIP_DELAY and is_ending_advance_input(event):
			complete_ending()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("retry") and state in [State.PLAYING, State.CLEARING, State.PAUSED, State.GAME_OVER]:
		retry_game()
		return
	if event.is_action_pressed("pause") and state in [State.PLAYING, State.PAUSED]:
		toggle_pause()
		return
	if is_pointer_over_menu_control(event):
		return
	if state == State.TITLE:
		if is_title_start_input(event):
			open_level_select()
			if event is InputEventScreenTouch or event is InputEventMouseButton:
				arm_level_select_pointer_guard(event is InputEventScreenTouch)
			get_viewport().set_input_as_handled()
		return
	if state in [State.LEVEL_SELECT, State.GAME_OVER]:
		if handle_menu_input(event):
			get_viewport().set_input_as_handled()
			return
		if (state == State.LEVEL_SELECT and is_confirm_input(event)) or (state == State.GAME_OVER and is_confirm_input(event)):
			start_game()
			get_viewport().set_input_as_handled()
			return
	if state != State.PLAYING:
		return
	if event.is_action_pressed("move_left"):
		try_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		try_move(Vector2i.RIGHT)
	elif event.is_action_pressed("rotate"):
		try_rotate()
	elif event.is_action_pressed("hard_drop"):
		hard_drop()
	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_touch_drag(event)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and should_handle_pointer_mouse():
		handle_mouse_click(event.position)

func is_start_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		# Android exposes hardware volume changes as key events. Restrict keyboard
		# start to deliberate confirm keys so volume never advances the title.
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return event.pressed and not event.echo and key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_X]
	if event is InputEventJoypadButton:
		return event.pressed
	# Pointer input is handled by the real Start/Restart button so the level
	# selector can receive clicks and touches without starting the game first.
	return false

func is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return event.pressed and not event.echo and key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	if event is InputEventJoypadButton:
		return event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]
	return false

func handle_debug_ending_shortcut(event: InputEvent) -> bool:
	if not OS.is_debug_build() or not (event is InputEventKey) or not event.pressed or event.echo:
		return false
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	# Godot reserves F7/F8 while running from the editor (F8 stops the game), so
	# the number keys are the dependable in-editor preview shortcuts. Keep the
	# function keys as aliases for standalone debug builds.
	if key in [KEY_7, KEY_F7]:
		open_ending_preview(false)
		return true
	if key in [KEY_8, KEY_F8]:
		open_ending_preview(true)
		return true
	return false

func is_ending_advance_input(event: InputEvent) -> bool:
	if is_confirm_input(event):
		return true
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT and should_handle_pointer_mouse()
	if event is InputEventScreenTouch:
		return event.pressed
	return false

func is_title_start_input(event: InputEvent) -> bool:
	if is_start_input(event):
		return true
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT and should_handle_pointer_mouse()
	if event is InputEventScreenTouch:
		return event.pressed
	return false

func is_pointer_over_menu_control(event: InputEvent) -> bool:
	var pointer_position := Vector2(-1, -1)
	if event is InputEventMouseButton:
		pointer_position = event.position
	elif event is InputEventScreenTouch:
		pointer_position = event.position
	if pointer_position.x < 0.0:
		return false
	var menu_controls: Array[Control] = [music_button, scores_button, back_button, start_button, pause_button, retry_button, controls_button, controls_close_button, name_entry, name_submit_button]
	menu_controls.append_array(mode_buttons)
	for control: Control in menu_controls:
		if control and control.visible and control.get_global_rect().has_point(pointer_position):
			return true
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_android_back()

func handle_android_back() -> void:
	if controls_visible:
		close_controls_screen()
		return
	match state:
		State.PLAYING, State.PAUSED:
			toggle_pause()
		State.CLEARING:
			pause_after_clear = true
		State.LEVEL_SELECT, State.HIGH_SCORES, State.GAME_OVER:
			secondary_menu_action()
		State.NAME_ENTRY:
			name_entry.release_focus()
			state = State.GAME_OVER
			update_menu_controls()
			queue_redraw()
		# Back on the title and during an ending is deliberately inert. Android's
		# Home gesture remains the safe way to leave without an accidental quit.
		_:
			pass

func handle_menu_input(event: InputEvent) -> bool:
	if state == State.LEVEL_SELECT and event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key in [KEY_LEFT, KEY_A]:
			adjust_start_level(-1)
			return true
		if key in [KEY_RIGHT, KEY_D]:
			adjust_start_level(1)
			return true
		if key in [KEY_UP, KEY_W]:
			adjust_start_level(-5)
			return true
		if key in [KEY_DOWN, KEY_S]:
			adjust_start_level(5)
			return true
		if key >= KEY_0 and key <= KEY_9:
			set_start_level(key - KEY_0)
			return true
	var pointer_position := Vector2(-1, -1)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and should_handle_pointer_mouse():
		pointer_position = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pointer_position = event.position
	if pointer_position.x < 0.0:
		return false
	if state == State.LEVEL_SELECT:
		for i in level_buttons.size():
			if level_button_rect(i).has_point(pointer_position):
				set_start_level(i)
				return true
	var active_start_rect := Rect2(start_button.position, start_button.size)
	if active_start_rect.has_point(pointer_position):
		start_game()
		return true
	return false

func primary_menu_action() -> void:
	if state == State.TITLE:
		open_level_select()
	elif state == State.PAUSED:
		toggle_pause()
	elif state in [State.LEVEL_SELECT, State.GAME_OVER]:
		if state == State.LEVEL_SELECT and level_select_pointer_guard:
			return
		start_game()

func arm_level_select_pointer_guard(from_touch: bool) -> void:
	# PRESS START overlaps the level-select START GAME button. Keep the pointer
	# sequence that opened this screen from activating the newly visible button.
	level_select_pointer_guard = true
	level_select_guard_from_touch = from_touch

func update_level_select_pointer_guard(event: InputEvent) -> void:
	if not level_select_pointer_guard or state != State.LEVEL_SELECT:
		return
	if event is InputEventScreenTouch and event.pressed:
		# A later touch press is a new, deliberate level-select interaction.
		level_select_pointer_guard = false
		level_select_guard_from_touch = false
	elif event is InputEventMouseButton and event.pressed and not level_select_guard_from_touch:
		# Likewise for a mouse-opened transition. Touch-generated mouse input stays
		# guarded because browsers may synthesize it after the touch release.
		level_select_pointer_guard = false
	elif is_confirm_input(event):
		level_select_pointer_guard = false
		level_select_guard_from_touch = false

func open_level_select(force := false) -> void:
	if state != State.TITLE and not force:
		return
	var from_title := state == State.TITLE
	state = State.LEVEL_SELECT
	if from_title:
		audio.play_ui_confirm()
	audio.play_title_music()
	update_menu_controls()
	start_button.release_focus()
	level_buttons[start_level].call_deferred("grab_focus")
	queue_redraw()

func level_button_rect(level_number: int) -> Rect2:
	var column := level_number % 5
	var row := level_number / 5
	return Rect2(LEVEL_GRID_ORIGIN + Vector2(column, row) * (LEVEL_BUTTON_SIZE + LEVEL_BUTTON_GAP), LEVEL_BUTTON_SIZE)

func handle_mouse_click(position: Vector2) -> void:
	if music_button and music_button.get_global_rect().has_point(position):
		return
	try_rotate()

func handle_touch(event: InputEventScreenTouch) -> void:
	last_touch_event_msec = Time.get_ticks_msec()
	if event.pressed:
		# Only one finger owns a gameplay gesture. Extra contacts must not move or
		# release the active piece gesture.
		if touch_active:
			return
		begin_touch_gesture(event.index, event.position)
		return
	if not touch_active or event.index != touch_index:
		return
	process_touch_motion(event.position)
	var completed_gesture := touch_gesture
	var completed_as_tap := touch_max_travel <= TOUCH_TAP_MAX_PIXELS
	reset_touch_gesture()
	if completed_gesture == TouchGesture.PENDING and completed_as_tap:
		try_rotate()

func begin_touch_gesture(index: int, position: Vector2) -> void:
	touch_active = true
	touch_index = index
	rebase_touch_gesture(position)
	touch_gesture = TouchGesture.CONTROLS if music_button and music_button.get_global_rect().has_point(position) else TouchGesture.PENDING

func rebase_touch_gesture(position: Vector2) -> void:
	var now_msec := Time.get_ticks_msec()
	touch_start = position
	touch_last = position
	touch_press_msec = now_msec
	touch_drag_remainder = Vector2.ZERO
	touch_max_travel = 0.0
	touch_down_transition = 0.0
	touch_transition_start_msec = now_msec
	touch_vertical_start_y = position.y
	touch_vertical_start_msec = now_msec
	touch_horizontal_direction = 0
	touch_horizontal_reversed = false
	touch_gesture = TouchGesture.PENDING

func reset_touch_gesture() -> void:
	touch_active = false
	touch_index = -1
	touch_gesture = TouchGesture.PENDING
	touch_drag_remainder = Vector2.ZERO
	touch_max_travel = 0.0
	touch_down_transition = 0.0
	touch_horizontal_direction = 0
	touch_horizontal_reversed = false

func handle_touch_during_clear(event: InputEvent) -> void:
	# The locked piece cannot accept gameplay movement, but Android touch life-cycle
	# events still have to be consumed. Track a fresh hold and continuously rebase
	# it so the first post-clear drag controls the newly spawned piece immediately.
	if event is InputEventScreenTouch:
		if event.pressed:
			if not touch_active:
				begin_touch_gesture(event.index, event.position)
		elif touch_active and event.index == touch_index:
			reset_touch_gesture()
	elif event is InputEventScreenDrag and touch_active and event.index == touch_index:
		rebase_touch_gesture(event.position)

func handle_touch_drag(event: InputEventScreenDrag) -> void:
	last_touch_event_msec = Time.get_ticks_msec()
	if touch_active and event.index == touch_index:
		process_touch_motion(event.position)

func process_touch_motion(position: Vector2) -> void:
	var now_msec := Time.get_ticks_msec()
	var frame_delta := position - touch_last
	touch_last = position
	touch_max_travel = maxf(touch_max_travel, position.distance_to(touch_start))
	if touch_gesture in [TouchGesture.CONTROLS, TouchGesture.HARD_DROP]:
		return
	var total_delta := position - touch_start
	if touch_gesture == TouchGesture.PENDING:
		if maxf(absf(total_delta.x), absf(total_delta.y)) < TOUCH_AXIS_LOCK_PIXELS:
			return
		if absf(total_delta.x) > absf(total_delta.y) * 1.2:
			touch_gesture = TouchGesture.HORIZONTAL
			touch_drag_remainder.x = total_delta.x
		elif absf(total_delta.y) > absf(total_delta.x) * 1.2:
			if total_delta.y < 0.0:
				# Upward motion has no gameplay action. Rebase instead of locking
				# the gesture, so the same held finger can still move or drop next.
				touch_start = position
				touch_drag_remainder = Vector2.ZERO
				return
			else:
				touch_gesture = TouchGesture.VERTICAL
				touch_drag_remainder.y = total_delta.y
				touch_vertical_start_y = touch_start.y
				touch_vertical_start_msec = touch_press_msec
		else:
			return
	elif touch_gesture == TouchGesture.HORIZONTAL:
		# Once horizontal positioning stops, a sustained, clearly downward turn
		# can take ownership without requiring the finger to lift first.
		if frame_delta.y > absf(frame_delta.x) * 1.25:
			if touch_down_transition <= 0.0:
				touch_transition_start_msec = now_msec
			touch_down_transition += frame_delta.y
			if touch_down_transition >= TOUCH_AXIS_CHANGE_PIXELS:
				touch_gesture = TouchGesture.VERTICAL
				touch_vertical_start_y = position.y - touch_down_transition
				touch_vertical_start_msec = touch_transition_start_msec
				touch_drag_remainder.y = touch_down_transition
		elif frame_delta.y < -absf(frame_delta.x) * 1.25:
			touch_down_transition = 0.0
		else:
			touch_down_transition = 0.0
			touch_drag_remainder.x += frame_delta.x
	elif touch_gesture == TouchGesture.VERTICAL:
		touch_drag_remainder.y += frame_delta.y

	if touch_gesture == TouchGesture.HORIZONTAL:
		while absf(touch_drag_remainder.x) >= TOUCH_HORIZONTAL_STEP_PIXELS:
			var direction := 1 if touch_drag_remainder.x > 0.0 else -1
			if touch_horizontal_direction != 0 and direction != touch_horizontal_direction:
				touch_horizontal_reversed = true
			touch_horizontal_direction = direction
			try_move(Vector2i(direction, 0))
			touch_drag_remainder.x -= direction * TOUCH_HORIZONTAL_STEP_PIXELS
	elif touch_gesture == TouchGesture.VERTICAL:
		var vertical_distance := position.y - touch_vertical_start_y
		var vertical_duration := now_msec - touch_vertical_start_msec
		if not touch_horizontal_reversed \
				and vertical_distance >= TOUCH_SWIPE_DROP_MIN_PIXELS \
				and vertical_duration <= TOUCH_SWIPE_DROP_MAX_MS:
			touch_gesture = TouchGesture.HARD_DROP
			hard_drop()
			return
		while touch_drag_remainder.y >= TOUCH_VERTICAL_STEP_PIXELS:
			if try_move(Vector2i.DOWN):
				score += 1
				audio.play_soft_drop()
			touch_drag_remainder.y -= TOUCH_VERTICAL_STEP_PIXELS

func should_handle_pointer_mouse() -> bool:
	# Android/iOS commonly synthesize a mouse click from every screen touch.
	# Handling that click as well as InputEventScreenTouch doubles every action.
	if OS.has_feature("mobile"):
		return false
	return Time.get_ticks_msec() - last_touch_event_msec > MOUSE_AFTER_TOUCH_SUPPRESS_MS

func process_keyboard_repeat(delta: float) -> void:
	var direction := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if direction == 0:
		repeat_direction = 0
		repeat_timer = 0.0
	elif direction != repeat_direction:
		repeat_direction = direction
		repeat_timer = GameConfig.DAS_SECONDS
	else:
		repeat_timer -= delta
		if repeat_timer <= 0.0:
			try_move(Vector2i(direction, 0))
			repeat_timer = GameConfig.ARR_SECONDS

func start_game() -> void:
	if state not in [State.LEVEL_SELECT, State.GAME_OVER]:
		return
	audio.play_ui_confirm()
	start_button.hide()
	start_button.release_focus()
	board.clear()
	score = 0
	lines = 0
	level = start_level
	gravity_accumulator = 0.0
	soft_drop_accumulator = 0.0
	lock_timer = 0.0
	clear_timer = 0.0
	clearing_rows.clear()
	line_clear_shards.clear()
	hard_drop_fx_timer = 0.0
	lock_flash_timer = 0.0
	lock_flash_cells.clear()
	ending_timer = 0.0
	cat_crowd_jump_timer = 0.0
	cat_crowd_positions.clear()
	cat_crowd_golden.clear()
	cat_crowd_fx_time = 0.0
	cat_crowd_rng.randomize()
	ending_preview_mode = false
	pause_after_clear = false
	flow_rise_accumulator = 0.0
	flow_pattern_index = 0
	flow_cascade_depth = 0
	flow_falling_cells.clear()
	flow_falling_kind = ""
	reset_touch_gesture()
	piece_randomizer.reset()
	if game_mode == GameMode.FLOWING:
		populate_flow_floor()
	next_kind = piece_randomizer.take_piece("D2") if game_mode == GameMode.FLOWING else piece_randomizer.next_piece()
	state = State.PLAYING
	update_menu_controls()
	audio.play_game_music()
	spawn_piece()
	if state == State.PLAYING and first_gameplay_controls_pending:
		show_first_gameplay_controls()

func show_first_gameplay_controls() -> void:
	controls_resume_gameplay = true
	controls_visible = true
	state = State.PAUSED
	audio.set_gameplay_paused(true)
	update_menu_controls()
	controls_close_button.call_deferred("grab_focus")
	queue_redraw()

func retry_game() -> void:
	# A dedicated entry point keeps retry behavior consistent across game-over,
	# pause, keyboard/controller shortcuts, and future touch UI.
	state = State.GAME_OVER
	start_game()

func spawn_piece() -> void:
	active = Polyomino.new(next_kind)
	next_kind = piece_randomizer.next_piece()
	gravity_accumulator = 0.0
	soft_drop_accumulator = 0.0
	lock_timer = 0.0
	if not board.fits(active, active.position, active.rotation):
		finish_run()

func populate_flow_floor() -> void:
	for pattern_offset in GameConfig.FLOW_STARTING_ROWS:
		var mask: String = GameConfig.FLOW_INITIAL_MASKS[pattern_offset % GameConfig.FLOW_INITIAL_MASKS.size()]
		var kind: String = GameConfig.PIECE_KINDS[(pattern_offset * 3 + 4) % GameConfig.PIECE_KINDS.size()]
		var y := GameConfig.BOARD_SIZE.y - 1 - pattern_offset
		for x in GameConfig.BOARD_SIZE.x:
			board.cells[y][x] = kind if mask[x] == "X" else ""

func build_flow_row(pattern_index: int) -> Array[String]:
	var mask: String = GameConfig.FLOW_RISING_MASKS[pattern_index % GameConfig.FLOW_RISING_MASKS.size()]
	var kind: String = GameConfig.PIECE_KINDS[(pattern_index * 5 + 2) % GameConfig.PIECE_KINDS.size()]
	var row: Array[String] = []
	for x in GameConfig.BOARD_SIZE.x:
		row.append(kind if mask[x] == "X" else "")
	return row

func advance_flow_floor() -> bool:
	var row := build_flow_row(flow_pattern_index)
	flow_pattern_index += 1
	if not board.push_up(row):
		return false
	# Shift the active piece with the scrolling coordinate field. Combined with
	# the fractional draw offset, this makes the row boundary visually seamless.
	if active:
		active.position += Vector2i.UP
	if active and not board.fits(active, active.position, active.rotation):
		return false
	return true

func finish_run() -> void:
	if state == State.ENDING:
		return
	audio.stop_music()
	ending_preview_mode = false
	ending_timer = 0.0
	state = State.ENDING
	audio.play_ending_music()
	update_menu_controls()
	queue_redraw()

func complete_ending() -> void:
	if state != State.ENDING:
		return
	audio.stop_music()
	if ending_preview_mode:
		state = ending_preview_return_state
		score = ending_preview_saved_score
		ending_preview_mode = false
		if state in [State.TITLE, State.LEVEL_SELECT, State.HIGH_SCORES]:
			audio.play_title_music()
		update_menu_controls()
		queue_redraw()
		return
	if SaveSystem.qualifies_for_high_score(score, high_scores):
		audio.play_high_score()
		state = State.NAME_ENTRY
		name_entry.text = str(SaveSystem.load_setting("player_name", ""))
		name_entry.call_deferred("grab_focus")
	else:
		state = State.GAME_OVER
	update_menu_controls()
	queue_redraw()

func open_ending_preview(lantern := false) -> void:
	if state not in [State.TITLE, State.LEVEL_SELECT, State.GAME_OVER, State.HIGH_SCORES] and not ending_preview_mode:
		return
	if not ending_preview_mode:
		ending_preview_return_state = state
		ending_preview_saved_score = score
	ending_preview_mode = true
	score = LANTERN_ENDING_SCORE if lantern else LANTERN_ENDING_SCORE - 1
	ending_timer = 0.0
	state = State.ENDING
	audio.stop_music()
	audio.play_ending_music()
	update_menu_controls()
	queue_redraw()

func try_move(offset: Vector2i) -> bool:
	var target := active.position + offset
	if board.fits(active, target, active.rotation):
		active.position = target
		if offset.x != 0:
			lock_timer = 0.0
			if audio:
				audio.play_move()
		return true
	return false

func try_rotate() -> void:
	var target_rotation := (active.rotation + 1) % Polyomino.rotation_count(active.kind)
	for kick in [0, -1, 1, -2, 2]:
		var target := active.position + Vector2i(kick, 0)
		if board.fits(active, target, target_rotation):
			active.position = target
			active.rotation = target_rotation
			lock_timer = 0.0
			audio.play_rotate()
			return
	audio.play_invalid()

func hard_drop() -> void:
	var start_position := active.position
	var distance := 0
	while try_move(Vector2i.DOWN):
		distance += 1
	begin_hard_drop_fx(start_position)
	score += distance * 2
	audio.play_drop(distance)
	lock_piece(false, true)

func begin_hard_drop_fx(start_position: Vector2i) -> void:
	hard_drop_kind = active.kind
	hard_drop_start_cells = active.cells(start_position, active.rotation)
	hard_drop_landed_cells = active.cells()
	build_hard_drop_shock()
	hard_drop_fx_timer = GameConfig.HARD_DROP_IMPACT_SECONDS

func build_hard_drop_shock() -> void:
	hard_drop_shock_pixels.clear()
	var min_x := 99
	var max_x := -99
	var bottom_y := -99
	for cell: Vector2i in hard_drop_landed_cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		bottom_y = maxi(bottom_y, cell.y + 1)
	var left := float(GameConfig.BOARD_ORIGIN.x + min_x * GameConfig.CELL_SIZE)
	var width := float((max_x - min_x + 1) * GameConfig.CELL_SIZE)
	var floor_y := float(GameConfig.BOARD_ORIGIN.y + bottom_y * GameConfig.CELL_SIZE)
	if game_mode == GameMode.FLOWING:
		floor_y += flow_board_offset_y()
	for i in 24:
		var side := -1.0 if i < 12 else 1.0
		var rank := i % 12
		var color: Color = CREAM if i % 3 == 0 else GameConfig.COLORS[hard_drop_kind].lightened(0.42)
		hard_drop_shock_pixels.append({
			"origin": Vector2(left + width * (float(i % 12) + 0.5) / 12.0, floor_y - 2.0 - float(i / 12) * 2.0),
			"velocity": Vector2(side * (25.0 + rank * 5.0), -32.0 - float((i * 11) % 31)),
			"size": 3.0 if i % 4 == 0 else 2.0,
			"color": color,
		})

func lock_piece(play_lock_sound := true, is_hard_drop := false) -> void:
	begin_lock_flash(is_hard_drop)
	if play_lock_sound:
		audio.play_lock()
	board.place(active)
	flow_cascade_depth = 0
	flow_falling_cells = active.cells().filter(func(cell: Vector2i) -> bool: return cell.y >= 0)
	flow_falling_kind = active.kind
	if game_mode == GameMode.FLOWING:
		# A Flowing piece stops as a rigid shape, then its individual cells pour
		# through every unsupported opening. This happens on every placement; a
		# line clear is an outcome of settling, not a prerequisite for gravity.
		flow_falling_cells = board.settle_tracked_cells(flow_falling_cells, flow_falling_kind)
		lock_flash_cells = flow_falling_cells.duplicate()
		if is_hard_drop:
			hard_drop_landed_cells = flow_falling_cells.duplicate()
			build_hard_drop_shock()
	# Every complete row resolves as soon as a piece locks. The next
	# piece is not spawned until the clear animation and removal finish.
	clearing_rows = board.full_rows()
	if clearing_rows.is_empty():
		spawn_piece()
	else:
		begin_line_clear(clearing_rows)

func begin_lock_flash(is_hard_drop: bool) -> void:
	lock_flash_cells = active.cells().duplicate()
	lock_flash_kind = active.kind
	lock_flash_is_hard = is_hard_drop
	lock_flash_duration = HARD_LOCK_FLASH_SECONDS if is_hard_drop else NORMAL_LOCK_FLASH_SECONDS
	lock_flash_timer = lock_flash_duration

func begin_line_clear(rows: Array[int]) -> void:
	state = State.CLEARING
	clear_timer = line_clear_seconds
	spawn_line_clear_shards(rows)

func spawn_line_clear_shards(rows: Array[int]) -> void:
	var cell_size := float(GameConfig.CELL_SIZE)
	var flow_offset := flow_board_offset_y()
	for row: int in rows:
		for x in GameConfig.BOARD_SIZE.x:
			var kind: String = board.cells[row][x]
			if kind == "":
				continue
			var cell_origin := Vector2(GameConfig.BOARD_ORIGIN + Vector2i(x, row) * GameConfig.CELL_SIZE)
			cell_origin.y += flow_offset
			var delay := float(x) / float(GameConfig.BOARD_SIZE.x - 1) * GameConfig.LINE_SHARD_SWEEP_SECONDS
			for shard_index in GameConfig.LINE_SHARDS_PER_BLOCK:
				var shard_column := shard_index % 4
				var shard_row := shard_index / 4
				var shard_size := Vector2(cell_size * 0.21, cell_size * 0.39)
				var local_center := Vector2(
					(float(shard_column) + 0.5) * cell_size / 4.0,
					(float(shard_row) + 0.5) * cell_size / 2.0
				)
				var color: Color = GameConfig.COLORS[kind].lightened(0.18 + float(shard_index % 3) * 0.08)
				line_clear_shards.append({
					"origin": cell_origin + local_center,
					"velocity": Vector2(
						line_shard_rng.randf_range(-42.0, 42.0) + float(x - 5) * 2.0,
						line_shard_rng.randf_range(-72.0, -18.0)
					),
					"size": shard_size,
					"angle": line_shard_rng.randf_range(-0.16, 0.16),
					"spin": line_shard_rng.randf_range(-7.0, 7.0),
					"age": -delay,
					"color": color,
				})

func update_line_clear_shards(delta: float) -> void:
	for shard_index in range(line_clear_shards.size() - 1, -1, -1):
		var shard: Dictionary = line_clear_shards[shard_index]
		shard.age = float(shard.age) + delta
		if float(shard.age) > GameConfig.LINE_SHARD_LIFETIME_SECONDS:
			line_clear_shards.remove_at(shard_index)

func is_clear_cell_fragmented(cell: Vector2i) -> bool:
	if state != State.CLEARING or not clearing_rows.has(cell.y):
		return false
	var elapsed := line_clear_seconds - clear_timer
	var delay := float(cell.x) / float(GameConfig.BOARD_SIZE.x - 1) * GameConfig.LINE_SHARD_SWEEP_SECONDS
	return elapsed >= delay

func finish_line_clear() -> void:
	# Revalidate after the visual pause so only genuinely complete rows can be removed.
	clearing_rows = clearing_rows.filter(func(row: int) -> bool: return board.is_row_full(row))
	var count := clearing_rows.size()
	if count == 0:
		clearing_rows.clear()
		state = State.PLAYING
		spawn_piece()
		pause_if_requested_after_clear()
		return
	var resolved_rows := clearing_rows.duplicate()
	board.remove_rows(resolved_rows)
	lock_flash_timer = 0.0
	lock_flash_cells.clear()
	audio.play_clear(count)
	var previous_level := level
	var cascade_multiplier := flow_cascade_depth + 1 if game_mode == GameMode.FLOWING else 1
	score += GameConfig.LINE_POINTS[count] * (level + 1) * cascade_multiplier
	lines += count
	if count == 5:
		add_crowd_cats(1, true)
	else:
		add_crowd_cats(count)
	level = mini(start_level + floori(lines / 10.0), GameConfig.MAX_LEVEL)
	if level > previous_level:
		audio.play_level_up()
	if count == 5:
		cat_happy_timer = 1.5
		cat_crowd_jump_timer = CAT_CROWD_JUMP_SECONDS
	if game_mode == GameMode.FLOWING:
		flow_falling_cells = board.remap_cells_after_row_removal(flow_falling_cells, resolved_rows)
		flow_falling_cells = board.settle_tracked_cells(flow_falling_cells, flow_falling_kind)
		var cascade_rows := board.full_rows()
		if not cascade_rows.is_empty():
			flow_cascade_depth += 1
			clearing_rows = cascade_rows
			begin_line_clear(clearing_rows)
			queue_redraw()
			return
	clearing_rows.clear()
	state = State.PLAYING
	spawn_piece()
	pause_if_requested_after_clear()

func pause_if_requested_after_clear() -> void:
	if not pause_after_clear or state != State.PLAYING:
		return
	pause_after_clear = false
	toggle_pause()

func ghost_y() -> int:
	var y := active.position.y
	while board.fits(active, Vector2i(active.position.x, y + 1), active.rotation):
		y += 1
	return y

func draw_tile(cell: Vector2i, kind: String, alpha := 1.0, use_ghost := false) -> void:
	var pos := Vector2(GameConfig.BOARD_ORIGIN + cell * GameConfig.CELL_SIZE)
	draw_tile_at(pos, kind, alpha, use_ghost)

func flow_board_offset_y() -> float:
	if game_mode != GameMode.FLOWING:
		return 0.0
	var interval := GameConfig.flow_rise_seconds(level)
	return -float(GameConfig.CELL_SIZE) * clampf(flow_rise_accumulator / interval, 0.0, 1.0)

func draw_flow_board_tile(cell: Vector2i, kind: String, alpha := 1.0, use_ghost := false) -> void:
	# Crop at the playfield edges so the logical one-row shift can happen exactly
	# when the continuously moving row becomes fully visible.
	var cell_size := float(GameConfig.CELL_SIZE)
	var pos := Vector2(GameConfig.BOARD_ORIGIN + cell * GameConfig.CELL_SIZE)
	pos.y += flow_board_offset_y()
	var board_top := float(GameConfig.BOARD_ORIGIN.y)
	var board_bottom := board_top + GameConfig.BOARD_SIZE.y * cell_size
	var visible_top := maxf(pos.y, board_top)
	var visible_bottom := minf(pos.y + cell_size, board_bottom)
	var visible_height := visible_bottom - visible_top
	if visible_height <= 0.0:
		return
	var crop_ratio := visible_height / cell_size
	var top_ratio := (visible_top - pos.y) / cell_size
	var texture: Texture2D = ghost_texture if use_ghost else tile_textures.get(kind)
	if texture:
		var texture_size := texture.get_size()
		var source := Rect2(0.0, texture_size.y * top_ratio, texture_size.x, texture_size.y * crop_ratio)
		draw_texture_rect_region(texture, Rect2(Vector2(pos.x, visible_top), Vector2(cell_size, visible_height)), source, Color(1, 1, 1, alpha))
		if not use_ghost and is_equal_approx(visible_height, cell_size):
			draw_wood_grain(pos, cell_size, kind, alpha)
		return
	var color: Color = GameConfig.COLORS[kind]
	color.a = alpha
	draw_rect(Rect2(Vector2(pos.x, visible_top), Vector2(cell_size, visible_height)), color)

func draw_tile_at(pos: Vector2, kind: String, alpha := 1.0, use_ghost := false, render_size := -1.0) -> void:
	var tile_size := float(GameConfig.CELL_SIZE) if render_size <= 0.0 else render_size
	var texture: Texture2D = ghost_texture if use_ghost else tile_textures.get(kind)
	if texture:
		draw_texture_rect(texture, Rect2(pos, Vector2(tile_size, tile_size)), false, Color(1, 1, 1, alpha))
		if not use_ghost:
			draw_wood_grain(pos, tile_size, kind, alpha)
		return
	var color: Color = GameConfig.COLORS[kind]
	color.a = alpha
	draw_rect(Rect2(pos, Vector2(tile_size, tile_size)), color)
	draw_rect(Rect2(pos + Vector2.ONE, Vector2(tile_size - 2.0, tile_size - 2.0)), color.lightened(0.13), false, 1.0)
	draw_line(pos + Vector2(2,2), pos + Vector2(tile_size - 3.0, 2), Color(1,1,1,0.24 * alpha), 1.0)
	draw_line(pos + Vector2(2,2), pos + Vector2(2, tile_size - 3.0), Color(1,1,1,0.20 * alpha), 1.0)
	draw_line(pos + Vector2(2, tile_size - 2.0), pos + Vector2(tile_size - 2.0, tile_size - 2.0), Color(0,0,0,0.30 * alpha), 1.0)
	draw_line(pos + Vector2(tile_size - 2.0, 2), pos + Vector2(tile_size - 2.0, tile_size - 2.0), Color(0,0,0,0.30 * alpha), 1.0)
	draw_wood_grain(pos, tile_size, kind, alpha)

func draw_wood_grain(pos: Vector2, tile_size: float, kind: String, alpha: float) -> void:
	var inset := maxf(2.0, floorf(tile_size * 0.16))
	var seed := kind.unicode_at(0) % 4
	var grain_color := Color(0.18, 0.10, 0.055, 0.18 * alpha)
	var highlight := Color(1.0, 0.84, 0.58, 0.10 * alpha)
	var first_y := pos.y + floorf(tile_size * (0.36 + seed * 0.015))
	var second_y := pos.y + floorf(tile_size * (0.68 - seed * 0.012))
	draw_line(Vector2(pos.x + inset, first_y), Vector2(pos.x + tile_size - inset - 1.0, first_y + 1.0), grain_color, 1.0)
	draw_line(Vector2(pos.x + inset + 2.0, second_y), Vector2(pos.x + tile_size - inset - 2.0, second_y - 1.0), highlight, 1.0)

func draw_panel(rect: Rect2, title: String, value: String) -> void:
	var texture: Texture2D = panel_textures.get(title)
	if texture:
		draw_texture_rect(texture, rect, false)
	else:
		draw_rect(rect, WOOD)
		draw_rect(rect.grow(-3), CREAM)
		draw_rect(Rect2(rect.position + Vector2(6,20), rect.size - Vector2(12,26)), PANEL)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8,15), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 11, Color("463426"))
	if value != "":
		var value_y := rect.position.y + rect.size.y * 0.77
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 8, value_y), value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 17, CREAM)

func _draw() -> void:
	if state == State.TITLE:
		draw_title_screen()
		if controls_visible:
			draw_controls_screen()
		return
	if state == State.LEVEL_SELECT:
		draw_level_select_screen()
		return
	if state == State.HIGH_SCORES:
		draw_high_scores_screen()
		return
	if state == State.ENDING:
		draw_stargazer_ending()
		return
	if background:
		draw_texture_rect(background, Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), false, Color(0.65,0.65,0.65,1))
	draw_rect(Rect2(0, 0, 360, 640), Color(0.07,0.055,0.045,0.70))
	if board_frame:
		# Stretch the existing wooden frame around the wider 14x24 opening. The
		# texture is decorative, so this avoids temporary replacement art.
		draw_texture_rect(board_frame, Rect2(-24, -33, 384, 753), false)
	var board_rect := Rect2(GameConfig.BOARD_ORIGIN, GameConfig.BOARD_SIZE * GameConfig.CELL_SIZE)
	draw_rect(board_rect, Color("151719"))
	for y in GameConfig.BOARD_SIZE.y + 1:
		var grid_y := float(GameConfig.BOARD_ORIGIN.y + y * GameConfig.CELL_SIZE)
		draw_line(Vector2(board_rect.position.x, grid_y), Vector2(board_rect.end.x, grid_y), Color(0.32,0.30,0.27,0.26))
	for x in GameConfig.BOARD_SIZE.x + 1:
		var grid_x := float(GameConfig.BOARD_ORIGIN.x + x * GameConfig.CELL_SIZE)
		draw_line(Vector2(grid_x, board_rect.position.y), Vector2(grid_x, board_rect.end.y), Color(0.32,0.30,0.27,0.26))
	for y in GameConfig.BOARD_SIZE.y:
		for x in GameConfig.BOARD_SIZE.x:
			if board.cells[y][x] != "":
				if is_clear_cell_fragmented(Vector2i(x, y)):
					continue
				if game_mode == GameMode.FLOWING:
					draw_flow_board_tile(Vector2i(x, y), board.cells[y][x])
				else:
					draw_tile(Vector2i(x,y), board.cells[y][x])
	if game_mode == GameMode.FLOWING and state in [State.PLAYING, State.PAUSED, State.CLEARING]:
		var incoming_row := build_flow_row(flow_pattern_index)
		for x in GameConfig.BOARD_SIZE.x:
			if incoming_row[x] != "":
				draw_flow_board_tile(Vector2i(x, GameConfig.BOARD_SIZE.y), incoming_row[x])
	if hard_drop_fx_timer > 0.0:
		draw_hard_drop_fx()
	if state == State.CLEARING:
		draw_line_clear_fx()
	if active and state in [State.PLAYING, State.PAUSED]:
		if state == State.PLAYING:
			for cell: Vector2i in active.cells(Vector2i(active.position.x, ghost_y()), active.rotation):
				if game_mode == GameMode.FLOWING:
					draw_flow_board_tile(cell, active.kind, 0.72, true)
				else:
					draw_tile(cell, active.kind, 0.72, true)
		for cell: Vector2i in active.cells():
			if cell.y >= 0:
				if game_mode == GameMode.FLOWING:
					draw_flow_board_tile(cell, active.kind)
				else:
					draw_tile(cell, active.kind)
	if not line_clear_shards.is_empty():
		draw_line_clear_shards()
	draw_cat_crowd()
	# Compact top HUD keeps all gameplay data clear of the playfield.
	draw_rect(Rect2(0, 0, 360, 108), Color(0.055, 0.045, 0.038, 0.90))
	draw_rect(Rect2(0, 106, 360, 2), WOOD_LIGHT)
	var next_rect := Rect2(254, 4, 102, 98)
	draw_panel(next_rect, "NEXT", "")
	draw_panel(Rect2(54, 4, 98, 47), "SCORE", "%06d" % score)
	draw_panel(Rect2(154, 4, 98, 47), "LEVEL", "%02d" % level)
	draw_panel(Rect2(54, 55, 98, 47), "LINES", "%03d" % lines)
	if next_kind != "":
		var preview := Polyomino.new(next_kind)
		var preview_cells := preview.cells(Vector2i.ZERO, 0)
		var min_cell := Vector2i(99, 99)
		var max_cell := Vector2i(-99, -99)
		for cell: Vector2i in preview_cells:
			min_cell.x = mini(min_cell.x, cell.x)
			min_cell.y = mini(min_cell.y, cell.y)
			max_cell.x = maxi(max_cell.x, cell.x)
			max_cell.y = maxi(max_cell.y, cell.y)
		var preview_tile_size := 11.0
		var piece_size := Vector2(max_cell - min_cell + Vector2i.ONE) * preview_tile_size
		var preview_center := Vector2(next_rect.position.x + next_rect.size.x * 0.5, next_rect.position.y + 65.0)
		var preview_origin := preview_center - piece_size * 0.5 - Vector2(min_cell) * preview_tile_size
		for cell: Vector2i in preview_cells:
			var p := preview_origin + Vector2(cell) * preview_tile_size
			draw_tile_at(p, next_kind, 1.0, false, preview_tile_size)
	var cat_texture: Texture2D = happy_textures[cat_frame] if cat_happy_timer > 0.0 else idle_textures[cat_frame]
	if cat_texture:
		draw_texture_rect(cat_texture, Rect2(4, 39, 46, 63), false)
	draw_string(ThemeDB.fallback_font, Vector2(154, 97), "HIGH %06d" % high_score, HORIZONTAL_ALIGNMENT_CENTER, 98, 10, Color("c8ad7f"))
	if game_mode == GameMode.FLOWING and state in [State.PLAYING, State.PAUSED, State.CLEARING]:
		draw_flow_warning(board_rect)
	if state == State.PAUSED:
		draw_overlay("PAUSED", "")
	elif state == State.GAME_OVER:
		draw_game_over_overlay()
	elif state == State.NAME_ENTRY:
		draw_name_entry_overlay()
	if controls_visible:
		draw_controls_screen()

func cat_crowd_count() -> int:
	return cat_crowd_positions.size()

func add_crowd_cats(count: int, golden := false) -> void:
	for _cat in maxi(0, count):
		cat_crowd_positions.append(Vector2(
			cat_crowd_rng.randf_range(CAT_CROWD_MIN.x, CAT_CROWD_MAX.x),
			cat_crowd_rng.randf_range(CAT_CROWD_MIN.y, CAT_CROWD_MAX.y)
		))
		cat_crowd_golden.append(golden)

func golden_cat_count() -> int:
	return cat_crowd_golden.count(true)

func draw_cat_crowd() -> void:
	if idle_textures.is_empty() or cat_crowd_count() == 0:
		return
	var cat_texture: Texture2D = idle_textures[0]
	if not cat_texture:
		return
	var jump_offset := 0.0
	if cat_crowd_jump_timer > 0.0:
		var jump_progress := 1.0 - cat_crowd_jump_timer / CAT_CROWD_JUMP_SECONDS
		jump_offset = sin(jump_progress * PI) * 11.0
	# Positions are rolled only when cats are earned, so the crowd is random but
	# visually stable. Overlap is intentional; CAT_CROWD_MIN.x is the hard wooden
	# boundary and the screen edge naturally clips the far side.
	for cat_index in range(cat_crowd_count() - 1, -1, -1):
		if cat_crowd_golden[cat_index]:
			continue
		var position := cat_crowd_positions[cat_index] - Vector2(0, jump_offset)
		draw_texture_rect(cat_texture, Rect2(position, CAT_CROWD_SIZE), false)
	if not golden_cat_texture:
		return
	# Golden five-line cats render last so their reward glow is never buried by the
	# ordinary crowd. The aura stays outside the playfield boundary.
	for cat_index in range(cat_crowd_count() - 1, -1, -1):
		if not cat_crowd_golden[cat_index]:
			continue
		var position := cat_crowd_positions[cat_index] - Vector2(0, jump_offset)
		var center := position + CAT_CROWD_SIZE * 0.5
		var pulse := 0.82 + 0.18 * sin(cat_crowd_fx_time * 4.2 + cat_index)
		draw_circle(center, 19.0 * pulse, Color(1.0, 0.67, 0.12, 0.035))
		draw_circle(center, 15.0 * pulse, Color(1.0, 0.79, 0.24, 0.065))
		draw_circle(center, 11.0 * pulse, Color(1.0, 0.91, 0.52, 0.10))
		draw_texture_rect(golden_cat_texture, Rect2(position, CAT_CROWD_SIZE), false)

func draw_stargazer_ending() -> void:
	if ending_background:
		draw_texture_rect(ending_background, Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), Color("07162d"))
	var lantern_ending := ending_name() == "LANTERN"
	if lantern_ending:
		draw_lantern_warmth()

	# A restrained shooting star gives the otherwise still illustration one
	# memorable event without competing with the supplied art.
	if not lantern_ending and ending_timer >= 2.0 and ending_timer <= 3.55:
		var star_progress := (ending_timer - 2.0) / 1.55
		var star_head := Vector2(334.0, 102.0).lerp(ENDING_NEW_STAR_POSITION, star_progress)
		var trail_direction := Vector2(1.0, -0.46).normalized()
		var trail_length := lerpf(18.0, 68.0, sin(star_progress * PI))
		var star_alpha := sin(star_progress * PI)
		draw_line(star_head, star_head + trail_direction * trail_length, Color(0.54, 0.75, 1.0, 0.16 * star_alpha), 9.0)
		draw_line(star_head, star_head + trail_direction * trail_length, Color(0.76, 0.88, 1.0, 0.42 * star_alpha), 4.0)
		draw_line(star_head, star_head + trail_direction * trail_length, Color(1.0, 0.96, 0.78, 0.92 * star_alpha), 1.25)
		draw_twinkle_star(star_head, ending_timer * 10.0, star_alpha, 0.78)
	if not lantern_ending and ending_timer >= 3.55:
		var birth_alpha := smoothstep(0.0, 1.0, clampf((ending_timer - 3.55) / 0.55, 0.0, 1.0))
		draw_twinkle_star(ENDING_NEW_STAR_POSITION, ending_timer * 4.8, birth_alpha, 1.0)
	elif lantern_ending:
		draw_ambient_lanterns()
		draw_rising_lanterns()

	var content_alpha := smoothstep(0.0, 1.0, clampf((ending_timer - 0.35) / 1.1, 0.0, 1.0))
	var title_color := Color(1.0, 0.82, 0.42, content_alpha) if lantern_ending else Color(0.98, 0.91, 0.72, content_alpha)
	var title_shadow := Color(0.02, 0.04, 0.10, 0.72 * content_alpha)
	draw_string(ThemeDB.fallback_font, Vector2(31, 258), "YOUR ENDING IS", HORIZONTAL_ALIGNMENT_CENTER, 300, 14, title_shadow)
	draw_string(ThemeDB.fallback_font, Vector2(30, 257), "YOUR ENDING IS", HORIZONTAL_ALIGNMENT_CENTER, 300, 14, Color(0.82, 0.87, 0.95, content_alpha))
	draw_string(ThemeDB.fallback_font, Vector2(31, 292), ending_name(), HORIZONTAL_ALIGNMENT_CENTER, 300, 27, title_shadow)
	draw_string(ThemeDB.fallback_font, Vector2(30, 290), ending_name(), HORIZONTAL_ALIGNMENT_CENTER, 300, 27, title_color)

	if ending_cat_sheet:
		var sequence_index := int(ending_timer / ENDING_CAT_FRAME_SECONDS) % ENDING_CAT_SEQUENCE.size()
		var frame_index: int = ENDING_CAT_SEQUENCE[sequence_index]
		var source_column := frame_index % 3
		var source_row := frame_index / 3
		var source_rect := Rect2(source_column * 512, source_row * 512, 512, 512)
		draw_texture_rect_region(ending_cat_sheet, Rect2(132, 427, 96, 96), source_rect, Color(1, 1, 1, content_alpha))

	if ending_score_plaque:
		draw_texture_rect(ending_score_plaque, Rect2(48, 526, 264, 89), false, Color(1, 1, 1, content_alpha))
		draw_string(ThemeDB.fallback_font, Vector2(76, 574), "FINAL SCORE  %06d" % score, HORIZONTAL_ALIGNMENT_CENTER, 208, 16, Color(0.98, 0.89, 0.68, content_alpha))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(58, 574), "FINAL SCORE  %06d" % score, HORIZONTAL_ALIGNMENT_CENTER, 244, 17, title_color)

	if ending_timer >= ENDING_SKIP_DELAY:
		var prompt_alpha := (0.48 + sin(ending_timer * 3.0) * 0.16) * content_alpha
		draw_string(ThemeDB.fallback_font, Vector2(70, 628), "TAP OR PRESS TO CONTINUE", HORIZONTAL_ALIGNMENT_CENTER, 220, 10, Color(0.82, 0.84, 0.88, prompt_alpha))

	var fade_alpha := 0.0
	if ending_timer < 0.7:
		fade_alpha = 1.0 - ending_timer / 0.7
	if fade_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), Color(0.0, 0.0, 0.0, clampf(fade_alpha, 0.0, 1.0)))

func ending_name() -> String:
	return "LANTERN" if score >= LANTERN_ENDING_SCORE else "STARGAZER"

func draw_lantern_warmth() -> void:
	var warmth := smoothstep(0.0, 1.0, clampf((ending_timer - 0.25) / 2.6, 0.0, 1.0))
	draw_rect(Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), Color(0.34, 0.12, 0.018, 0.105 * warmth))
	# Nested, very low-alpha pools behave as a soft grade while preserving every
	# detail in the original rooftop painting.
	draw_circle(Vector2(180, 414), 235.0, Color(1.0, 0.42, 0.06, 0.018 * warmth))
	draw_circle(Vector2(180, 430), 178.0, Color(1.0, 0.52, 0.08, 0.022 * warmth))
	draw_circle(Vector2(180, 446), 118.0, Color(1.0, 0.66, 0.16, 0.026 * warmth))

func draw_rising_lanterns() -> void:
	# Begin the release with the ending itself. The first group launches together;
	# later lanterns follow quickly without changing their ascent duration.
	var lantern_time := maxf(0.0, ending_timer)
	for lantern_index in 18:
		var queued_index := maxi(0, lantern_index - LANTERN_INITIAL_RISING_COUNT + 1)
		var delay := queued_index * LANTERN_RISING_SPAWN_SECONDS
		var elapsed := lantern_time - delay
		if elapsed < 0.0:
			continue
		var duration := 24.0 + float((lantern_index * 7) % 9) * 1.02
		var progress := fposmod(elapsed, duration) / duration
		# Every launch point sits on the distant horizon behind the cathedral.
		# The opening fade lets each lantern appear from behind the roofline rather
		# than drawing across the foreground terrace or telescope.
		# A low-discrepancy step spreads consecutive launches across the church
		# horizon instead of forming two obvious vertical columns at high density.
		var start_x := 176.0 + float((lantern_index * 43) % 136)
		var drift := sin(progress * TAU + lantern_index * 1.37) * (5.0 + float(lantern_index % 3) * 2.0)
		var position := Vector2(start_x + drift, lerpf(374.0, 48.0, progress))
		var depth_scale := 0.88 + float((lantern_index * 5) % 6) * 0.055
		# Fade across a fraction of a second, not a fraction of the long flight.
		var launch_fade := smoothstep(0.0, 0.20, elapsed)
		var edge_fade := launch_fade * (1.0 - smoothstep(0.88, 1.0, progress))
		draw_lantern(position, depth_scale, lantern_time * 4.0 + lantern_index, edge_fade)

func draw_ambient_lanterns() -> void:
	# These distant lanterns are already gathered in the church-tower depth
	# layer when the scene opens. They hover rather than joining the ascent.
	var reveal := smoothstep(0.0, 1.0, clampf(ending_timer / 0.9, 0.0, 1.0))
	for lantern_index in LANTERN_AMBIENT_POSITIONS.size():
		var phase := ending_timer * (0.72 + lantern_index * 0.035) + lantern_index * 1.31
		var bob := sin(phase) * (1.4 + float(lantern_index % 3) * 0.45)
		var position: Vector2 = LANTERN_AMBIENT_POSITIONS[lantern_index] + Vector2(0, bob)
		var depth_scale := 0.72 + float((lantern_index * 3) % 5) * 0.035
		draw_lantern(position, depth_scale, phase * 3.2, reveal * 0.82)

func draw_lantern(position: Vector2, scale: float, phase: float, alpha: float) -> void:
	var flicker := 0.82 + 0.18 * sin(phase)
	var glow_alpha := alpha * flicker
	draw_circle(position, 16.0 * scale, Color(1.0, 0.46, 0.06, 0.045 * glow_alpha))
	draw_circle(position, 11.0 * scale, Color(1.0, 0.65, 0.12, 0.085 * glow_alpha))
	draw_circle(position, 7.0 * scale, Color(1.0, 0.83, 0.34, 0.15 * glow_alpha))
	if lantern_texture:
		var sprite_size := Vector2(13.0, 16.25) * scale
		var tilt := sin(phase * 0.31) * 0.055
		draw_set_transform(position, tilt, Vector2.ONE)
		draw_texture_rect(lantern_texture, Rect2(-sprite_size * 0.5, sprite_size), false, Color(1.0, 0.94 + 0.06 * flicker, 0.82 + 0.18 * flicker, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_twinkle_star(position: Vector2, phase: float, alpha: float, scale: float) -> void:
	var pulse := 0.76 + 0.24 * sin(phase)
	var fast_pulse := 0.70 + 0.30 * sin(phase * 1.73 + 0.8)
	var vertical_radius := 7.2 * scale * pulse
	var horizontal_radius := 5.4 * scale * fast_pulse
	var diagonal_radius := 3.2 * scale * (0.82 + 0.18 * sin(phase * 1.31))
	draw_circle(position, 8.0 * scale, Color(0.48, 0.72, 1.0, 0.13 * alpha * pulse))
	draw_line(position - Vector2(0, vertical_radius), position + Vector2(0, vertical_radius), Color(0.86, 0.94, 1.0, 0.82 * alpha), 1.15)
	draw_line(position - Vector2(horizontal_radius, 0), position + Vector2(horizontal_radius, 0), Color(1.0, 0.92, 0.68, 0.88 * alpha), 1.15)
	var diagonal := Vector2(diagonal_radius, diagonal_radius)
	draw_line(position - diagonal, position + diagonal, Color(0.72, 0.86, 1.0, 0.48 * alpha), 0.8)
	draw_line(position - Vector2(diagonal.x, -diagonal.y), position + Vector2(diagonal.x, -diagonal.y), Color(0.72, 0.86, 1.0, 0.42 * alpha), 0.8)
	draw_circle(position, 2.0 * scale, Color(1.0, 0.97, 0.78, alpha))

func draw_title_screen() -> void:
	if title_background:
		draw_texture_rect(title_background, Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), Color("07162d"))
	if OS.is_debug_build():
		draw_string(ThemeDB.fallback_font, Vector2(45, 630), "DEBUG  7: STARGAZER   8: LANTERN", HORIZONTAL_ALIGNMENT_CENTER, 270, 8, Color(0.72, 0.77, 0.86, 0.78))

func draw_level_select_screen() -> void:
	if level_select_background:
		draw_texture_rect(level_select_background, Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), false, Color(0.62, 0.62, 0.62, 1.0))
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), Color("241b15"))
	draw_rect(Rect2(36, 366, 288, 226), Color(0.055, 0.05, 0.04, 0.91))
	draw_rect(Rect2(36, 366, 288, 226), Color("b8935d"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(50, 393), "CHOOSE MODE & PACE", HORIZONTAL_ALIGNMENT_CENTER, 260, 18, CREAM)

func draw_flow_warning(board_rect: Rect2) -> void:
	var pulse := 0.78 + sin(Time.get_ticks_msec() * 0.006) * 0.10
	var warning_color := Color(0.95, 0.73, 0.34, pulse)
	var warning_rect := Rect2(board_rect.end.x - 72, board_rect.position.y + 6, 66, 22)
	draw_rect(warning_rect, Color(0.04, 0.035, 0.03, 0.78))
	draw_rect(warning_rect, warning_color, false, 1.0)
	draw_string(ThemeDB.fallback_font, warning_rect.position + Vector2(4, 15), "FLOWING  ↑", HORIZONTAL_ALIGNMENT_CENTER, 58, 9, warning_color)

func draw_high_scores_screen() -> void:
	if level_select_background:
		draw_texture_rect(level_select_background, Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), false, Color(0.42, 0.42, 0.42, 1.0))
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), Color("241b15"))
	draw_rect(Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), Color(0.03, 0.025, 0.02, 0.48))
	if board_frame:
		draw_texture_rect(board_frame, Rect2(-16, -33, 364, 753), false)
	var panel := Rect2(55, 112, 250, 430)
	draw_rect(panel, Color("111315"))
	draw_string(ThemeDB.fallback_font, Vector2(66, 154), "HIGH SCORES", HORIZONTAL_ALIGNMENT_CENTER, 228, 25, CREAM)
	draw_line(Vector2(75, 170), Vector2(285, 170), WOOD_LIGHT, 2.0)
	if high_scores.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(70, 254), "NO SCORES YET", HORIZONTAL_ALIGNMENT_CENTER, 220, 16, Color("c8ad7f"))
	else:
		for i in mini(high_scores.size(), SaveSystem.MAX_HIGH_SCORES):
			var entry: Dictionary = high_scores[i]
			var row_y := 202.0 + i * 30.0
			var rank_color := Color("f0d58f") if i < 3 else Color("c8ad7f")
			draw_string(ThemeDB.fallback_font, Vector2(70, row_y), "%2d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, 24, 13, rank_color)
			draw_string(ThemeDB.fallback_font, Vector2(98, row_y), str(entry.name), HORIZONTAL_ALIGNMENT_LEFT, 94, 13, CREAM)
			draw_string(ThemeDB.fallback_font, Vector2(190, row_y), "%06d" % int(entry.score), HORIZONTAL_ALIGNMENT_RIGHT, 98, 13, rank_color)

func draw_game_over_overlay() -> void:
	var rect := Rect2(46, 210, 268, 306)
	draw_rect(rect, Color(0.06,0.05,0.04,0.96))
	draw_rect(rect, WOOD_LIGHT, false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(58, 258), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, 244, 28, CREAM)
	draw_string(ThemeDB.fallback_font, Vector2(58, 300), "SCORE  %06d" % score, HORIZONTAL_ALIGNMENT_CENTER, 244, 15, Color("e2c98f"))
	draw_string(ThemeDB.fallback_font, Vector2(58, 330), "LINES  %03d     LEVEL  %02d" % [lines, level], HORIZONTAL_ALIGNMENT_CENTER, 244, 12, Color("c8ad7f"))

func draw_name_entry_overlay() -> void:
	var rect := Rect2(46, 208, 268, 220)
	draw_rect(rect, Color(0.06, 0.05, 0.04, 0.97))
	draw_rect(rect, WOOD_LIGHT, false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(58, 258), "NEW HIGH SCORE", HORIZONTAL_ALIGNMENT_CENTER, 244, 24, CREAM)
	draw_string(ThemeDB.fallback_font, Vector2(58, 288), "%06d" % score, HORIZONTAL_ALIGNMENT_CENTER, 244, 18, Color("e2c98f"))

func draw_hard_drop_fx() -> void:
	var age := GameConfig.HARD_DROP_IMPACT_SECONDS - hard_drop_fx_timer
	var impact_progress := clampf(age / GameConfig.HARD_DROP_IMPACT_SECONDS, 0.0, 1.0)
	var cell_size := float(GameConfig.CELL_SIZE)
	var tile_width: float
	var tile_height: float
	if impact_progress < 0.45:
		var rebound := smoothstep(0.0, 1.0, impact_progress / 0.45)
		tile_width = lerpf(cell_size + 3.0, cell_size - 1.0, rebound)
		tile_height = lerpf(cell_size * 0.44, cell_size + 1.5, rebound)
	else:
		var settle := smoothstep(0.0, 1.0, (impact_progress - 0.45) / 0.55)
		tile_width = lerpf(cell_size - 0.5, cell_size, settle)
		tile_height = lerpf(cell_size + 1.0, cell_size, settle)
	var texture: Texture2D = tile_textures.get(hard_drop_kind)
	for cell: Vector2i in hard_drop_landed_cells:
		if cell.y < 0:
			continue
		var tile_pos := Vector2(GameConfig.BOARD_ORIGIN + cell * GameConfig.CELL_SIZE)
		if game_mode == GameMode.FLOWING:
			tile_pos.y += flow_board_offset_y()
		draw_rect(Rect2(tile_pos, Vector2(cell_size, cell_size)), Color(0.08, 0.09, 0.10, 0.08))
		var impact_rect := Rect2(tile_pos + Vector2((cell_size - tile_width) * 0.5, (cell_size - tile_height) * 0.5), Vector2(tile_width, tile_height))
		if texture:
			draw_texture_rect(texture, impact_rect, false, Color(1.0, 0.96, 0.86, 0.60))
		else:
			var impact_color: Color = GameConfig.COLORS[hard_drop_kind]
			impact_color.a = 0.60
			draw_rect(impact_rect, impact_color)
	draw_hard_drop_pixel_shock(age)

func draw_hard_drop_comet(alpha: float) -> void:
	var min_x := 99
	var max_x := -99
	var landed_top_row := 99
	for cell: Vector2i in hard_drop_landed_cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		landed_top_row = mini(landed_top_row, cell.y)
	var footprint_left := float(GameConfig.BOARD_ORIGIN.x + min_x * GameConfig.CELL_SIZE)
	var footprint_width := float((max_x - min_x + 1) * GameConfig.CELL_SIZE)
	var center_x := footprint_left + footprint_width * 0.5
	# Always begin at the visible board ceiling. A stack near the top therefore
	# still receives a bright beam instead of reducing the effect to a few motes.
	var beam_top := float(GameConfig.BOARD_ORIGIN.y)
	var beam_bottom := float(GameConfig.BOARD_ORIGIN.y + landed_top_row * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE * 0.72)
	if game_mode == GameMode.FLOWING:
		beam_bottom += flow_board_offset_y()
	var beam_height := maxf(float(GameConfig.CELL_SIZE), beam_bottom - beam_top)
	var piece_color: Color = GameConfig.COLORS[hard_drop_kind]

	# Layered tapered polygons form a continuous light column while preserving
	# the board underneath through low alpha. The warm halo inherits the wood
	# stain; the narrow cream core provides the magical beam-of-light read.
	var halo := piece_color.lightened(0.38)
	halo.a = alpha * 0.10
	var halo_half_top := footprint_width * 0.34 + 11.0
	var halo_half_bottom := footprint_width * 0.58 + 20.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - halo_half_top, beam_top),
		Vector2(center_x + halo_half_top, beam_top),
		Vector2(center_x + halo_half_bottom, beam_bottom),
		Vector2(center_x - halo_half_bottom, beam_bottom),
	]), halo)
	var gold_half_top := footprint_width * 0.22 + 5.0
	var gold_half_bottom := footprint_width * 0.40 + 9.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - gold_half_top, beam_top),
		Vector2(center_x + gold_half_top, beam_top),
		Vector2(center_x + gold_half_bottom, beam_bottom),
		Vector2(center_x - gold_half_bottom, beam_bottom),
	]), Color(1.0, 0.68, 0.25, alpha * 0.12))
	var core_half_top := maxf(3.0, footprint_width * 0.07)
	var core_half_bottom := maxf(6.0, footprint_width * 0.14)
	draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - core_half_top, beam_top),
		Vector2(center_x + core_half_top, beam_top),
		Vector2(center_x + core_half_bottom, beam_bottom),
		Vector2(center_x - core_half_bottom, beam_bottom),
	]), Color(1.0, 0.97, 0.78, alpha * 0.25))

	# Fine vertical shafts make the beam shimmer rather than reading as a flat
	# translucent shape.
	for streak in 9:
		var ratio := (float(streak) + 0.5) / 9.0
		var offset := (ratio - 0.5) * footprint_width * 0.82
		var stagger := float((streak * 17) % 23)
		var streak_alpha := alpha * (0.10 + (1.0 - absf(ratio - 0.5) * 2.0) * 0.16)
		draw_line(
			Vector2(round(center_x + offset * 0.55), beam_top + stagger),
			Vector2(round(center_x + offset), beam_bottom - float((streak * 11) % 18)),
			Color(1.0, 0.91, 0.60, streak_alpha),
			2.0 if streak in [3, 4, 5] else 1.0
		)

	# Three translucent piece-shaped echoes show the actual fall inside the beam.
	if hard_drop_start_cells.size() == hard_drop_landed_cells.size():
		for echo in 3:
			var travel := float(echo + 1) / 4.0
			var echo_alpha := alpha * (0.09 + travel * 0.11)
			for cell_index in hard_drop_start_cells.size():
				var start_cell := Vector2(hard_drop_start_cells[cell_index])
				var landed_cell := Vector2(hard_drop_landed_cells[cell_index])
				var echo_cell := start_cell.lerp(landed_cell, travel)
				var echo_pos := Vector2(GameConfig.BOARD_ORIGIN) + echo_cell * GameConfig.CELL_SIZE
				if game_mode == GameMode.FLOWING:
					echo_pos.y += flow_board_offset_y()
				draw_tile_at(echo_pos, hard_drop_kind, echo_alpha)

	# Sparse star motes sit outside the core and keep the effect handcrafted.
	var mote_count := maxi(6, ceili(beam_height / 34.0))
	for mote in mote_count:
		var vertical_ratio := (float(mote) + 0.5) / float(mote_count)
		var side := -1.0 if mote % 2 == 0 else 1.0
		var x := center_x + side * (footprint_width * 0.42 + float((mote * 13) % 17))
		var y := beam_top + vertical_ratio * beam_height
		var radius := 2.0 + float(mote % 3)
		draw_pixel_star(Vector2(round(x), round(y)), radius, Color(1.0, 0.94, 0.66, alpha * (0.25 + vertical_ratio * 0.32)))

func draw_pixel_star(position: Vector2, radius: float, color: Color) -> void:
	draw_rect(Rect2(position - Vector2.ONE, Vector2(3, 3)), color)
	draw_rect(Rect2(position + Vector2(-radius - 1.0, 0), Vector2(radius * 2.0 + 3.0, 1)), color)
	draw_rect(Rect2(position + Vector2(0, -radius - 1.0), Vector2(1, radius * 2.0 + 3.0)), color)

func draw_hard_drop_pixel_shock(age: float) -> void:
	var life := GameConfig.HARD_DROP_IMPACT_SECONDS
	var alpha := clampf(1.0 - age / life, 0.0, 1.0)
	if hard_drop_landed_cells.is_empty():
		return
	var min_x := 99
	var max_x := -99
	var bottom_y := -99
	for cell: Vector2i in hard_drop_landed_cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		bottom_y = maxi(bottom_y, cell.y + 1)
	if age < 0.12:
		var shock_alpha := 1.0 - age / 0.12
		var line_y := float(GameConfig.BOARD_ORIGIN.y + bottom_y * GameConfig.CELL_SIZE - 1)
		if game_mode == GameMode.FLOWING:
			line_y += flow_board_offset_y()
		var contact_expand := age / 0.12 * 10.0
		var line_left := float(GameConfig.BOARD_ORIGIN.x + min_x * GameConfig.CELL_SIZE - 5) - contact_expand
		var line_right := float(GameConfig.BOARD_ORIGIN.x + (max_x + 1) * GameConfig.CELL_SIZE + 5) + contact_expand
		var hot := Color(1.0, 0.98, 0.78, shock_alpha)
		var glow: Color = GameConfig.COLORS[hard_drop_kind].lightened(0.48)
		glow.a = shock_alpha * 0.78
		draw_line(Vector2(line_left, line_y), Vector2(line_right, line_y), glow, 3.0)
		draw_line(Vector2(line_left + 2.0, line_y - 1.0), Vector2(line_right - 2.0, line_y - 1.0), hot, 1.0)
		draw_pixel_star(Vector2(line_left, line_y - 1.0), 3.0, hot)
		draw_pixel_star(Vector2(line_right, line_y - 1.0), 3.0, hot)
	for pixel in hard_drop_shock_pixels:
		var origin: Vector2 = pixel["origin"]
		var velocity: Vector2 = pixel["velocity"]
		var position := origin + velocity * age + Vector2(0, 150.0 * age * age)
		var color: Color = pixel["color"]
		color.a = alpha
		var size: float = pixel["size"]
		draw_rect(Rect2(Vector2(round(position.x), round(position.y)), Vector2(size, size)), color)

func draw_line_clear_fx() -> void:
	var elapsed := line_clear_seconds - clear_timer
	var flow_offset := flow_board_offset_y()
	for row in clearing_rows:
		for x in GameConfig.BOARD_SIZE.x:
			var delay := float(x) / float(GameConfig.BOARD_SIZE.x - 1) * GameConfig.LINE_SHARD_SWEEP_SECONDS
			var flash_age := elapsed - delay
			if flash_age < 0.0 or flash_age > 0.11:
				continue
			var flash_alpha := 1.0 - flash_age / 0.11
			var pos := Vector2(GameConfig.BOARD_ORIGIN + Vector2i(x, row) * GameConfig.CELL_SIZE)
			pos.y += flow_offset
			var center := pos + Vector2.ONE * GameConfig.CELL_SIZE * 0.5
			draw_circle(center, GameConfig.CELL_SIZE * (0.72 + flash_age * 4.0), Color(1.0, 0.72, 0.25, 0.12 * flash_alpha))
			draw_rect(Rect2(pos + Vector2(1, 1), Vector2.ONE * (GameConfig.CELL_SIZE - 2)), Color(1.0, 0.98, 0.78, 0.88 * flash_alpha), false, 2.0)
			draw_line(center - Vector2(8, 0), center + Vector2(8, 0), Color(1.0, 0.90, 0.55, 0.72 * flash_alpha), 1.0)

func draw_line_clear_shards() -> void:
	const SHARD_GRAVITY := 360.0
	for shard: Dictionary in line_clear_shards:
		var age := float(shard.age)
		if age < 0.0:
			continue
		var fade := 1.0 - smoothstep(0.48, GameConfig.LINE_SHARD_LIFETIME_SECONDS, age)
		var velocity: Vector2 = shard.velocity
		var position: Vector2 = shard.origin + velocity * age + Vector2(0, SHARD_GRAVITY * age * age * 0.5)
		var angle := float(shard.angle) + float(shard.spin) * age
		var half_size: Vector2 = Vector2(shard.size) * 0.5
		var polygon := PackedVector2Array([
			position + Vector2(-half_size.x, -half_size.y).rotated(angle),
			position + Vector2(half_size.x, -half_size.y * 0.82).rotated(angle),
			position + Vector2(half_size.x * 0.78, half_size.y).rotated(angle),
			position + Vector2(-half_size.x, half_size.y * 0.72).rotated(angle),
		])
		var color: Color = shard.color
		color.a = fade
		if age < 0.12:
			var burst := (1.0 - age / 0.12) * fade
			draw_circle(position, maxf(half_size.x, half_size.y) * 1.8, Color(1.0, 0.72, 0.24, 0.10 * burst))
			draw_line(position, position - velocity.normalized() * 7.0, Color(1.0, 0.93, 0.66, 0.36 * burst), 1.0)
		draw_colored_polygon(polygon, Color(0.16, 0.09, 0.04, fade * 0.70))
		var inner := PackedVector2Array()
		for point: Vector2 in polygon:
			inner.append(position + (point - position) * 0.78)
		draw_colored_polygon(inner, color)

func draw_overlay(title: String, subtitle: String) -> void:
	var rect := Rect2(38, 190, 284, 294) if subtitle == "" else Rect2(38, 250, 284, 112)
	draw_rect(rect, Color(0.06,0.05,0.04,0.94))
	draw_rect(rect, WOOD_LIGHT, false, 3.0)
	var title_y := 250.0 if subtitle == "" else 296.0
	draw_string(ThemeDB.fallback_font, Vector2(48, title_y), title, HORIZONTAL_ALIGNMENT_CENTER, 264, 26, CREAM)
	if subtitle != "":
		draw_string(ThemeDB.fallback_font, Vector2(48, 328), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 264, 12, Color("c8ad7f"))

func draw_controls_screen() -> void:
	var rect := CONTROLS_PANEL_RECT
	draw_rect(Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), Color(0.015, 0.02, 0.04, 0.78))
	draw_rect(rect, Color(0.055, 0.048, 0.042, 0.985))
	draw_rect(rect, WOOD_LIGHT, false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(40, 112), "HOW TO PLAY", HORIZONTAL_ALIGNMENT_CENTER, 280, 26, CREAM)
	draw_string(ThemeDB.fallback_font, Vector2(40, 137), "TOUCH CONTROLS", HORIZONTAL_ALIGNMENT_CENTER, 280, 10, Color("c8ad7f"))
	var rows := [
		["TAP", "ROTATE"],
		["SWIPE LEFT / RIGHT", "MOVE"],
		["DRAG DOWN", "SOFT DROP"],
		["QUICK SWIPE DOWN", "HARD DROP"],
	]
	for row_index in rows.size():
		var row_y := 178.0 + row_index * 72.0
		draw_rect(Rect2(42, row_y - 22, 276, 54), Color(0.10, 0.085, 0.068, 0.72))
		draw_line(Vector2(48, row_y + 33), Vector2(312, row_y + 33), Color(0.66, 0.49, 0.29, 0.45), 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(52, row_y), rows[row_index][0], HORIZONTAL_ALIGNMENT_LEFT, 160, 12, Color(0.86, 0.78, 0.62))
		draw_string(ThemeDB.fallback_font, Vector2(202, row_y), rows[row_index][1], HORIZONTAL_ALIGNMENT_RIGHT, 104, 14, CREAM)
	draw_string(ThemeDB.fallback_font, Vector2(42, 482), "PAUSE FOR RETRY OR LEVEL SELECT", HORIZONTAL_ALIGNMENT_CENTER, 276, 10, Color("c8ad7f"))
