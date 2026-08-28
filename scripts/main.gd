extends Control

enum State { TITLE, PLAYING, CLEARING, PAUSED, GAME_OVER }

const PANEL := Color("1d1b1a")
const CREAM := Color("efe2be")
const WOOD := Color("68462f")
const WOOD_LIGHT := Color("a7754a")
const START_BUTTON_RECT := Rect2(88, 292, 184, 38)
const LEVEL_DOWN_RECT := Rect2(82, 340, 48, 36)
const LEVEL_UP_RECT := Rect2(230, 340, 48, 36)

var board := GameBoard.new()
var active: Tetromino
var next_kind := ""
var state := State.TITLE
var score := 0
var lines := 0
var level := 0
var start_level := 0
var line_clear_seconds := GameConfig.LINE_CLEAR_SECONDS
var high_score := 0
var gravity_accumulator := 0.0
var soft_drop_accumulator := 0.0
var lock_timer := 0.0
var clear_timer := 0.0
var clearing_rows: Array[int] = []
var repeat_direction := 0
var repeat_timer := 0.0
var touch_start := Vector2.ZERO
var touch_last := Vector2.ZERO
var touch_active := false
var cat_happy_timer := 0.0
var cat_frame_timer := 0.0
var cat_frame := 0
var hard_drop_fx_timer := 0.0
var hard_drop_start_cells: Array = []
var hard_drop_landed_cells: Array = []
var hard_drop_shock_pixels: Array = []
var hard_drop_kind := ""
var piece_randomizer := PieceRandomizer.new()
var audio: AudioSystem
var background: Texture2D
var idle_textures: Array[Texture2D] = []
var happy_textures: Array[Texture2D] = []
var tile_textures: Dictionary = {}
var ghost_texture: Texture2D
var line_clear_frames: Array[Texture2D] = []
var start_button: Button
var level_down_button: Button
var level_up_button: Button
var level_select_label: Label
var line_clear_slider: HSlider
var line_clear_label: Label

func _ready() -> void:
	setup_input_map()
	audio = AudioSystem.new()
	add_child(audio)
	high_score = SaveSystem.load_high_score()
	background = load("res://assets/backgrounds/cat_room.png")
	for i in range(1, 5):
		idle_textures.append(load("res://assets/cat/idle_%02d.png" % i))
		happy_textures.append(load("res://assets/cat/happy_%02d.png" % i))
	load_block_textures()
	create_start_button()
	create_level_selector()
	create_line_clear_tuner()
	set_process(true)
	queue_redraw()

func load_block_textures() -> void:
	for kind in ["I", "O", "T", "S", "Z", "J", "L"]:
		var path := "res://assets/blocks/processed/tile_%s.png" % kind.to_lower()
		if ResourceLoader.exists(path):
			tile_textures[kind] = load(path)
	ghost_texture = load("res://assets/blocks/processed/ghost.png")
	for i in range(1, 7):
		line_clear_frames.append(load("res://assets/fx/line_clear/frame_%02d.png" % i))

func create_start_button() -> void:
	start_button = Button.new()
	start_button.position = Vector2(88, 292)
	start_button.size = Vector2(184, 38)
	start_button.text = "START GAME"
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.add_theme_font_size_override("font_size", 16)
	start_button.pressed.connect(start_game)
	add_child(start_button)
	start_button.call_deferred("grab_focus")

func create_level_selector() -> void:
	level_down_button = Button.new()
	level_down_button.position = Vector2(82, 340)
	level_down_button.size = Vector2(48, 36)
	level_down_button.text = "−"
	level_down_button.pressed.connect(adjust_start_level.bind(-1))
	add_child(level_down_button)

	level_select_label = Label.new()
	level_select_label.position = Vector2(132, 340)
	level_select_label.size = Vector2(96, 36)
	level_select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_select_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_select_label.add_theme_font_size_override("font_size", 15)
	add_child(level_select_label)

	level_up_button = Button.new()
	level_up_button.position = Vector2(230, 340)
	level_up_button.size = Vector2(48, 36)
	level_up_button.text = "+"
	level_up_button.pressed.connect(adjust_start_level.bind(1))
	add_child(level_up_button)
	set_start_level(0)

func adjust_start_level(amount: int) -> void:
	set_start_level(start_level + amount)

func set_start_level(value: int) -> void:
	start_level = clampi(value, 0, GameConfig.MAX_LEVEL)
	if level_select_label:
		level_select_label.text = "LEVEL %d" % start_level

func create_line_clear_tuner() -> void:
	line_clear_label = Label.new()
	line_clear_label.position = Vector2(82, 380)
	line_clear_label.size = Vector2(196, 20)
	line_clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_clear_label.add_theme_font_size_override("font_size", 12)
	add_child(line_clear_label)

	line_clear_slider = HSlider.new()
	line_clear_slider.position = Vector2(82, 400)
	line_clear_slider.size = Vector2(196, 24)
	line_clear_slider.min_value = 0.08
	line_clear_slider.max_value = 0.40
	line_clear_slider.step = 0.01
	line_clear_slider.value = line_clear_seconds
	line_clear_slider.value_changed.connect(set_line_clear_seconds)
	add_child(line_clear_slider)
	set_line_clear_seconds(line_clear_seconds)

func set_line_clear_seconds(value: float) -> void:
	line_clear_seconds = clampf(value, 0.08, 0.40)
	if line_clear_label:
		line_clear_label.text = "LINE CLEAR  %d ms" % roundi(line_clear_seconds * 1000.0)

func setup_input_map() -> void:
	bind_keys("move_left", [KEY_A, KEY_LEFT])
	bind_keys("move_right", [KEY_D, KEY_RIGHT])
	bind_keys("soft_drop", [KEY_S, KEY_DOWN])
	bind_keys("hard_drop", [KEY_SPACE])
	bind_keys("rotate", [KEY_X, KEY_UP])
	bind_keys("pause", [KEY_P, KEY_ESCAPE])
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
	update_start_button()
	if hard_drop_fx_timer > 0.0:
		hard_drop_fx_timer = maxf(0.0, hard_drop_fx_timer - delta)
	cat_frame_timer += delta
	if cat_frame_timer >= 0.22:
		cat_frame_timer = 0.0
		cat_frame = (cat_frame + 1) % 4
	if cat_happy_timer > 0.0:
		cat_happy_timer -= delta

	if state == State.CLEARING:
		clear_timer -= delta
		if clear_timer <= 0.0:
			finish_line_clear()
	elif state == State.PLAYING:
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

func update_start_button() -> void:
	var should_show := state in [State.TITLE, State.GAME_OVER]
	level_down_button.visible = should_show
	level_up_button.visible = should_show
	level_select_label.visible = should_show
	line_clear_slider.visible = should_show
	line_clear_label.visible = should_show
	if start_button.visible != should_show:
		start_button.visible = should_show
		if should_show:
			start_button.text = "RESTART" if state == State.GAME_OVER else "START GAME"
			start_button.grab_focus()
	if should_show and not start_button.has_focus():
		start_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and state in [State.PLAYING, State.PAUSED]:
		state = State.PLAYING if state == State.PAUSED else State.PAUSED
		return
	if state in [State.TITLE, State.GAME_OVER]:
		if handle_menu_input(event):
			get_viewport().set_input_as_handled()
			return
		if is_start_input(event):
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
		touch_last = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_mouse_click(event.position)

func is_start_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	# Pointer input is handled by the real Start/Restart button so the level
	# selector can receive clicks and touches without starting the game first.
	return false

func handle_menu_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key in [KEY_LEFT, KEY_A]:
			adjust_start_level(-1)
			return true
		if key in [KEY_RIGHT, KEY_D]:
			adjust_start_level(1)
			return true
		if key >= KEY_0 and key <= KEY_9:
			set_start_level(key - KEY_0)
			return true
	var pointer_position := Vector2(-1, -1)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_position = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pointer_position = event.position
	if pointer_position.x < 0.0:
		return false
	if LEVEL_DOWN_RECT.has_point(pointer_position):
		adjust_start_level(-1)
		return true
	if LEVEL_UP_RECT.has_point(pointer_position):
		adjust_start_level(1)
		return true
	if START_BUTTON_RECT.has_point(pointer_position):
		start_game()
		return true
	return false

func handle_mouse_click(position: Vector2) -> void:
	if position.y >= 572.0:
		if position.x < 90.0:
			try_move(Vector2i.LEFT)
		elif position.x < 180.0:
			try_rotate()
		elif position.x < 270.0:
			try_move(Vector2i.RIGHT)
		else:
			hard_drop()
	else:
		try_rotate()

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_active = true
		touch_start = event.position
		touch_last = event.position
		return
	if not touch_active:
		return
	touch_active = false
	var delta := touch_last - touch_start
	if touch_start.y >= 572.0:
		if touch_start.x < 90.0: try_move(Vector2i.LEFT)
		elif touch_start.x < 180.0: try_rotate()
		elif touch_start.x < 270.0: try_move(Vector2i.RIGHT)
		else: hard_drop()
	elif abs(delta.x) > abs(delta.y) and abs(delta.x) > 18.0:
		var steps := clampi(roundi(abs(delta.x) / 22.0), 1, 5)
		for i in steps: try_move(Vector2i(sign(delta.x), 0))
	elif delta.y > 20.0:
		var steps := clampi(roundi(delta.y / 18.0), 1, 8)
		for i in steps:
			if try_move(Vector2i.DOWN): score += 1
	elif delta.y < -28.0:
		hard_drop()
	else:
		try_rotate()

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
	if state not in [State.TITLE, State.GAME_OVER]:
		return
	start_button.hide()
	start_button.release_focus()
	board.clear()
	score = 0
	lines = 0
	level = start_level
	piece_randomizer.reset()
	next_kind = piece_randomizer.next_piece()
	state = State.PLAYING
	spawn_piece()

func spawn_piece() -> void:
	active = Tetromino.new(next_kind)
	next_kind = piece_randomizer.next_piece()
	gravity_accumulator = 0.0
	soft_drop_accumulator = 0.0
	lock_timer = 0.0
	if not board.fits(active, active.position, active.rotation):
		state = State.GAME_OVER
		audio.play_game_over()
		if score > high_score:
			high_score = score
			SaveSystem.save_high_score(high_score)

func try_move(offset: Vector2i) -> bool:
	var target := active.position + offset
	if board.fits(active, target, active.rotation):
		active.position = target
		if offset.x != 0:
			lock_timer = 0.0
		return true
	return false

func try_rotate() -> void:
	var states: Array = Tetromino.SHAPES[active.kind]
	var target_rotation := (active.rotation + 1) % states.size()
	for kick in [0, -1, 1, -2, 2]:
		var target := active.position + Vector2i(kick, 0)
		if board.fits(active, target, target_rotation):
			active.position = target
			active.rotation = target_rotation
			lock_timer = 0.0
			audio.play_rotate()
			return

func hard_drop() -> void:
	var start_position := active.position
	var distance := 0
	while try_move(Vector2i.DOWN):
		distance += 1
	begin_hard_drop_fx(start_position)
	score += distance * 2
	audio.play_drop()
	lock_piece()

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
	var left := float(GameConfig.BOARD_ORIGIN.x + min_x * 16)
	var width := float((max_x - min_x + 1) * 16)
	var floor_y := float(GameConfig.BOARD_ORIGIN.y + bottom_y * 16)
	for i in 12:
		var side := -1.0 if i < 6 else 1.0
		var rank := i % 6
		var color: Color = CREAM if i % 3 == 0 else GameConfig.COLORS[hard_drop_kind].lightened(0.28)
		hard_drop_shock_pixels.append({
			"origin": Vector2(left + width * (float(i) + 0.5) / 12.0, floor_y - 1.0),
			"velocity": Vector2(side * (21.0 + rank * 7.0), -25.0 - float((i * 9) % 22)),
			"size": 2.0 if i % 2 == 0 else 1.0,
			"color": color,
		})

func lock_piece() -> void:
	board.place(active)
	clearing_rows = board.full_rows()
	if clearing_rows.is_empty():
		spawn_piece()
	else:
		state = State.CLEARING
		clear_timer = line_clear_seconds

func finish_line_clear() -> void:
	var count := clearing_rows.size()
	board.remove_rows(clearing_rows)
	audio.play_clear(count)
	score += GameConfig.LINE_POINTS[count] * (level + 1)
	lines += count
	level = mini(start_level + floori(lines / 10.0), GameConfig.MAX_LEVEL)
	if count == 4:
		cat_happy_timer = 1.5
	clearing_rows.clear()
	state = State.PLAYING
	spawn_piece()

func ghost_y() -> int:
	var y := active.position.y
	while board.fits(active, Vector2i(active.position.x, y + 1), active.rotation):
		y += 1
	return y

func draw_tile(cell: Vector2i, kind: String, alpha := 1.0, use_ghost := false) -> void:
	var pos := Vector2(GameConfig.BOARD_ORIGIN + cell * GameConfig.CELL_SIZE)
	draw_tile_at(pos, kind, alpha, use_ghost)

func draw_tile_at(pos: Vector2, kind: String, alpha := 1.0, use_ghost := false) -> void:
	var texture: Texture2D = ghost_texture if use_ghost else tile_textures.get(kind)
	if texture:
		draw_texture_rect(texture, Rect2(pos, Vector2(16, 16)), false, Color(1, 1, 1, alpha))
		return
	var color: Color = GameConfig.COLORS[kind]
	color.a = alpha
	draw_rect(Rect2(pos, Vector2(16,16)), color)
	draw_rect(Rect2(pos + Vector2(1,1), Vector2(14,14)), color.lightened(0.13), false, 1.0)
	draw_line(pos + Vector2(2,2), pos + Vector2(13,2), Color(1,1,1,0.24 * alpha), 1.0)
	draw_line(pos + Vector2(2,2), pos + Vector2(2,13), Color(1,1,1,0.20 * alpha), 1.0)
	draw_line(pos + Vector2(2,14), pos + Vector2(14,14), Color(0,0,0,0.30 * alpha), 1.0)
	draw_line(pos + Vector2(14,2), pos + Vector2(14,14), Color(0,0,0,0.30 * alpha), 1.0)

func draw_panel(rect: Rect2, title: String, value: String) -> void:
	draw_rect(rect, WOOD)
	draw_rect(rect.grow(-3), CREAM)
	draw_rect(Rect2(rect.position + Vector2(6,20), rect.size - Vector2(12,26)), PANEL)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8,15), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 11, Color("463426"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8,42), value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 18, CREAM)

func _draw() -> void:
	if background:
		draw_texture_rect(background, Rect2(Vector2.ZERO, Vector2(GameConfig.LOGICAL_SIZE)), false, Color(0.65,0.65,0.65,1))
	draw_rect(Rect2(15, 106, 330, 448), Color(0.07,0.055,0.045,0.88))
	draw_rect(Rect2(21, 135, 174, 334), WOOD_LIGHT)
	draw_rect(Rect2(25, 139, 166, 326), Color("151719"))
	for y in GameConfig.BOARD_SIZE.y + 1:
		draw_line(Vector2(28,142 + y*16), Vector2(188,142 + y*16), Color(0.32,0.30,0.27,0.35))
	for x in GameConfig.BOARD_SIZE.x + 1:
		draw_line(Vector2(28 + x*16,142), Vector2(28 + x*16,462), Color(0.32,0.30,0.27,0.35))
	for y in GameConfig.BOARD_SIZE.y:
		for x in GameConfig.BOARD_SIZE.x:
			if board.cells[y][x] != "":
				draw_tile(Vector2i(x,y), board.cells[y][x])
	if hard_drop_fx_timer > 0.0:
		draw_hard_drop_fx()
	if state == State.CLEARING:
		draw_line_clear_fx()
	if active and state in [State.PLAYING, State.PAUSED]:
		if state == State.PLAYING:
			for cell: Vector2i in active.cells(Vector2i(active.position.x, ghost_y()), active.rotation):
				draw_tile(cell, active.kind, 0.72, true)
		for cell: Vector2i in active.cells():
			if cell.y >= 0: draw_tile(cell, active.kind)
	draw_panel(Rect2(205, 142, 132, 64), "SCORE", "%06d" % score)
	draw_panel(Rect2(205, 214, 132, 64), "LEVEL", "%02d" % level)
	draw_panel(Rect2(205, 286, 132, 64), "LINES", "%03d" % lines)
	draw_panel(Rect2(205, 358, 132, 94), "NEXT", "")
	if next_kind != "":
		var preview := Tetromino.new(next_kind)
		for cell: Vector2i in preview.cells(Vector2i.ZERO, 0):
			var p := Vector2(232 + cell.x*16, 389 + cell.y*16)
			draw_tile_at(p, next_kind)
	var cat_texture: Texture2D = happy_textures[cat_frame] if cat_happy_timer > 0.0 else idle_textures[cat_frame]
	if cat_texture:
		draw_texture_rect(cat_texture, Rect2(221, 448, 100, 120), false)
	draw_string(ThemeDB.fallback_font, Vector2(18, 42), "COZY CAT BLOCKS", HORIZONTAL_ALIGNMENT_CENTER, 324, 26, CREAM)
	draw_string(ThemeDB.fallback_font, Vector2(18, 68), "HIGH %06d" % high_score, HORIZONTAL_ALIGNMENT_CENTER, 324, 12, Color("c8ad7f"))
	draw_touch_controls()
	if state == State.TITLE:
		draw_overlay("COZY CAT BLOCKS", "")
	elif state == State.PAUSED:
		draw_overlay("PAUSED", "PRESS P TO CONTINUE")
	elif state == State.GAME_OVER:
		draw_overlay("GAME OVER", "")

func draw_hard_drop_fx() -> void:
	var age := GameConfig.HARD_DROP_IMPACT_SECONDS - hard_drop_fx_timer
	var trail_alpha := clampf(1.0 - age / GameConfig.HARD_DROP_TRAIL_SECONDS, 0.0, 1.0)
	if trail_alpha > 0.0:
		# Three readable silhouettes communicate distance better than abstract streaks.
		for echo_index in 3:
			var path_ratio := float(echo_index + 1) / 4.0
			var echo_alpha := trail_alpha * (0.10 + echo_index * 0.07)
			for i in mini(hard_drop_start_cells.size(), hard_drop_landed_cells.size()):
				var start_cell: Vector2i = hard_drop_start_cells[i]
				var end_cell: Vector2i = hard_drop_landed_cells[i]
				var start_pixel := Vector2(GameConfig.BOARD_ORIGIN + start_cell * 16)
				var end_pixel := Vector2(GameConfig.BOARD_ORIGIN + end_cell * 16)
				var echo_position := start_pixel.lerp(end_pixel, path_ratio)
				if echo_position.y >= GameConfig.BOARD_ORIGIN.y:
					draw_tile_at(echo_position, hard_drop_kind, echo_alpha)
	var impact_progress := clampf(age / GameConfig.HARD_DROP_IMPACT_SECONDS, 0.0, 1.0)
	var tile_width: float
	var tile_height: float
	if impact_progress < 0.45:
		var rebound := smoothstep(0.0, 1.0, impact_progress / 0.45)
		tile_width = lerpf(19.0, 15.0, rebound)
		tile_height = lerpf(7.0, 17.5, rebound)
	else:
		var settle := smoothstep(0.0, 1.0, (impact_progress - 0.45) / 0.55)
		tile_width = lerpf(15.5, 16.0, settle)
		tile_height = lerpf(17.0, 16.0, settle)
	var texture: Texture2D = tile_textures.get(hard_drop_kind)
	for cell: Vector2i in hard_drop_landed_cells:
		if cell.y < 0:
			continue
		var tile_pos := Vector2(GameConfig.BOARD_ORIGIN + cell * 16)
		draw_rect(Rect2(tile_pos, Vector2(16,16)), Color("151719"))
		var impact_rect := Rect2(tile_pos + Vector2((16.0 - tile_width) * 0.5, (16.0 - tile_height) * 0.5), Vector2(tile_width, tile_height))
		if texture:
			draw_texture_rect(texture, impact_rect, false)
		else:
			draw_rect(impact_rect, GameConfig.COLORS[hard_drop_kind])
	draw_hard_drop_pixel_shock(age)

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
	if age < 0.055:
		var shock_alpha := 1.0 - age / 0.055
		var line_y := float(GameConfig.BOARD_ORIGIN.y + bottom_y * 16 - 1)
		var contact_expand := age / 0.055 * 5.0
		var line_left := float(GameConfig.BOARD_ORIGIN.x + min_x * 16 - 5) - contact_expand
		var line_right := float(GameConfig.BOARD_ORIGIN.x + (max_x + 1) * 16 + 5) + contact_expand
		draw_line(Vector2(line_left, line_y), Vector2(line_right, line_y), Color(1.0, 0.88, 0.58, shock_alpha), 2.0)
		draw_rect(Rect2(Vector2(line_left - 2.0, line_y - 2.0), Vector2(2, 2)), Color(1.0, 0.88, 0.58, shock_alpha))
		draw_rect(Rect2(Vector2(line_right, line_y - 2.0), Vector2(2, 2)), Color(1.0, 0.88, 0.58, shock_alpha))
	for pixel in hard_drop_shock_pixels:
		var origin: Vector2 = pixel["origin"]
		var velocity: Vector2 = pixel["velocity"]
		var position := origin + velocity * age + Vector2(0, 150.0 * age * age)
		var color: Color = pixel["color"]
		color.a = alpha
		var size: float = pixel["size"]
		draw_rect(Rect2(Vector2(round(position.x), round(position.y)), Vector2(size, size)), color)

func draw_line_clear_fx() -> void:
	var progress := clampf(1.0 - clear_timer / line_clear_seconds, 0.0, 1.0)
	var board_left := float(GameConfig.BOARD_ORIGIN.x)
	var board_center := board_left + GameConfig.BOARD_SIZE.x * GameConfig.CELL_SIZE * 0.5
	for row in clearing_rows:
		var row_y := float(GameConfig.BOARD_ORIGIN.y + row * GameConfig.CELL_SIZE)
		var wipe := smoothstep(0.0, 1.0, clampf((progress - 0.16) / 0.62, 0.0, 1.0))
		var half_width := 80.0 * wipe
		draw_rect(Rect2(board_center - half_width, row_y, half_width * 2.0, 16), Color("151719"))
		if not line_clear_frames.is_empty():
			var frame_index := mini(floori(progress * line_clear_frames.size()), line_clear_frames.size() - 1)
			# Keep the glow focused around the cleared row instead of covering nearby play.
			var effect_rect := Rect2(board_center - 104.0, row_y - 24.0, 208, 64)
			draw_texture_rect(line_clear_frames[frame_index], effect_rect, false)

func draw_touch_controls() -> void:
	var labels := ["LEFT", "TURN", "RIGHT", "DROP"]
	for i in 4:
		var rect := Rect2(i * 90 + 3, 580, 84, 48)
		draw_rect(rect, Color(0.12,0.10,0.08,0.82))
		draw_rect(rect, Color("b28a59"), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(4,29), labels[i], HORIZONTAL_ALIGNMENT_CENTER, 76, 12, CREAM)

func draw_overlay(title: String, subtitle: String) -> void:
	var rect := Rect2(38, 215, 284, 224) if subtitle == "" else Rect2(38, 250, 284, 112)
	draw_rect(rect, Color(0.06,0.05,0.04,0.94))
	draw_rect(rect, WOOD_LIGHT, false, 3.0)
	var title_y := 276.0 if subtitle == "" else 296.0
	draw_string(ThemeDB.fallback_font, Vector2(48, title_y), title, HORIZONTAL_ALIGNMENT_CENTER, 264, 26, CREAM)
	if subtitle != "":
		draw_string(ThemeDB.fallback_font, Vector2(48, 328), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 264, 12, Color("c8ad7f"))
