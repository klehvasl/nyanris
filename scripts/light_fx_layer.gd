extends Control

var game: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive

func _draw() -> void:
	if not game:
		return
	if game.hard_drop_fx_timer > 0.0:
		var age: float = GameConfig.HARD_DROP_IMPACT_SECONDS - game.hard_drop_fx_timer
		var trail_alpha := clampf(1.0 - age / GameConfig.HARD_DROP_TRAIL_SECONDS, 0.0, 1.0)
		if trail_alpha > 0.0 and not game.hard_drop_landed_cells.is_empty():
			draw_drop_beam(trail_alpha)
	if game.lock_flash_timer > 0.0:
		draw_lock_light()

func draw_lock_light() -> void:
	var progress := clampf(1.0 - game.lock_flash_timer / game.lock_flash_duration, 0.0, 1.0)
	# A fast primary burst followed by one smaller glint feels like emitted light,
	# not an opaque tint blinking on and off.
	var primary := exp(-progress * (7.0 if game.lock_flash_is_hard else 9.0))
	var secondary_center := 0.42 if game.lock_flash_is_hard else 0.34
	var secondary_width := 0.12 if game.lock_flash_is_hard else 0.10
	var secondary := exp(-pow((progress - secondary_center) / secondary_width, 2.0))
	var intensity := primary + secondary * (0.48 if game.lock_flash_is_hard else 0.24)
	var stain: Color = GameConfig.COLORS[game.lock_flash_kind]
	var warm := stain.lightened(0.48)
	for cell: Vector2i in game.lock_flash_cells:
		if cell.y < 0:
			continue
		var pos := Vector2(GameConfig.BOARD_ORIGIN + cell * GameConfig.CELL_SIZE)
		pos.y += game.flow_board_offset_y()
		var center := pos + Vector2(GameConfig.CELL_SIZE, GameConfig.CELL_SIZE) * 0.5
		# Concentric, low-alpha blooms approximate radial falloff under additive blend.
		draw_circle(center, 18.0, Color(warm.r, warm.g, warm.b, intensity * 0.045))
		draw_circle(center, 12.0, Color(1.0, 0.72, 0.30, intensity * 0.065))
		draw_circle(center, 7.0, Color(1.0, 0.94, 0.68, intensity * 0.12))
		var tile_rect := Rect2(pos + Vector2(2, 2), Vector2(GameConfig.CELL_SIZE - 4, GameConfig.CELL_SIZE - 4))
		draw_rect(tile_rect, Color(1.0, 0.85, 0.48, intensity * 0.055))
		draw_rect(tile_rect.grow(-1.0), Color(1.0, 0.98, 0.82, intensity * 0.22), false, 1.0)
		if intensity > 0.15:
			draw_light_star(center, 3.0 if game.lock_flash_is_hard else 2.0, Color(1.0, 1.0, 0.88, intensity * 0.38))

func draw_drop_beam(alpha: float) -> void:
	var min_x := 99
	var max_x := -99
	var landed_top_row := 99
	for cell: Vector2i in game.hard_drop_landed_cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		landed_top_row = mini(landed_top_row, cell.y)
	var footprint_left := float(GameConfig.BOARD_ORIGIN.x + min_x * GameConfig.CELL_SIZE)
	var footprint_width := float((max_x - min_x + 1) * GameConfig.CELL_SIZE)
	var center_x := footprint_left + footprint_width * 0.5
	var beam_top := float(GameConfig.BOARD_ORIGIN.y)
	var beam_bottom := float(GameConfig.BOARD_ORIGIN.y + landed_top_row * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE * 0.72)
	beam_bottom += game.flow_board_offset_y()
	var beam_height := maxf(float(GameConfig.CELL_SIZE), beam_bottom - beam_top)
	var light_alpha := pow(alpha, 0.68)
	var stain: Color = GameConfig.COLORS[game.hard_drop_kind]

	draw_tapered_beam(center_x, beam_top, beam_bottom, footprint_width * 0.78 + 28.0, footprint_width + 46.0, Color(stain.lightened(0.45), light_alpha * 0.055))
	draw_tapered_beam(center_x, beam_top, beam_bottom, footprint_width * 0.46 + 12.0, footprint_width * 0.72 + 20.0, Color(1.0, 0.56, 0.16, light_alpha * 0.075))
	draw_tapered_beam(center_x, beam_top, beam_bottom, maxf(9.0, footprint_width * 0.18), maxf(18.0, footprint_width * 0.30), Color(1.0, 0.91, 0.54, light_alpha * 0.13))

	# Additive shafts create a white-hot core with a soft falloff.
	draw_line(Vector2(center_x, beam_top), Vector2(center_x, beam_bottom), Color(1.0, 0.67, 0.22, light_alpha * 0.09), 14.0)
	draw_line(Vector2(center_x, beam_top), Vector2(center_x, beam_bottom), Color(1.0, 0.91, 0.58, light_alpha * 0.16), 7.0)
	draw_line(Vector2(center_x, beam_top), Vector2(center_x, beam_bottom), Color(1.0, 1.0, 0.88, light_alpha * 0.40), 2.0)

	for streak in 7:
		var ratio := (float(streak) + 0.5) / 7.0
		var offset := (ratio - 0.5) * footprint_width * 0.78
		var stagger := float((streak * 19) % 29)
		draw_line(
			Vector2(center_x + offset * 0.48, beam_top + stagger),
			Vector2(center_x + offset, beam_bottom - float((streak * 7) % 21)),
			Color(1.0, 0.88, 0.47, light_alpha * 0.14),
			1.0
		)

	# Piece-shaped echoes are lights, not opaque duplicate blocks.
	if game.hard_drop_start_cells.size() == game.hard_drop_landed_cells.size():
		var texture: Texture2D = game.tile_textures.get(game.hard_drop_kind)
		for echo in 3:
			var travel := float(echo + 1) / 4.0
			var echo_alpha := light_alpha * (0.055 + travel * 0.055)
			for cell_index in game.hard_drop_start_cells.size():
				var start_cell := Vector2(game.hard_drop_start_cells[cell_index])
				var landed_cell := Vector2(game.hard_drop_landed_cells[cell_index])
				var echo_cell := start_cell.lerp(landed_cell, travel)
				var pos := Vector2(GameConfig.BOARD_ORIGIN) + echo_cell * GameConfig.CELL_SIZE
				pos.y += game.flow_board_offset_y()
				if texture:
					draw_texture_rect(texture, Rect2(pos, Vector2(GameConfig.CELL_SIZE, GameConfig.CELL_SIZE)), false, Color(1.0, 0.88, 0.55, echo_alpha))

	# Entry flare and landing bloom anchor the vertical shaft in the scene.
	draw_light_star(Vector2(center_x, beam_top + 2.0), 7.0, Color(1.0, 1.0, 0.84, light_alpha * 0.55))
	var landing := Vector2(center_x, beam_bottom)
	draw_circle(landing, footprint_width * 0.72 + 20.0, Color(stain.lightened(0.5), light_alpha * 0.035))
	draw_circle(landing, footprint_width * 0.43 + 10.0, Color(1.0, 0.66, 0.22, light_alpha * 0.065))
	draw_circle(landing, footprint_width * 0.20 + 5.0, Color(1.0, 0.96, 0.70, light_alpha * 0.13))
	draw_light_star(landing, 9.0, Color(1.0, 1.0, 0.90, light_alpha * 0.62))

	var mote_count := maxi(6, ceili(beam_height / 38.0))
	for mote in mote_count:
		var vertical_ratio := (float(mote) + 0.5) / float(mote_count)
		var side := -1.0 if mote % 2 == 0 else 1.0
		var x := center_x + side * (footprint_width * 0.40 + float((mote * 13) % 19))
		var y := beam_top + vertical_ratio * beam_height
		draw_light_star(Vector2(round(x), round(y)), 2.0 + float(mote % 3), Color(1.0, 0.91, 0.55, light_alpha * 0.24))

func draw_tapered_beam(center_x: float, top: float, bottom: float, top_width: float, bottom_width: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - top_width * 0.5, top),
		Vector2(center_x + top_width * 0.5, top),
		Vector2(center_x + bottom_width * 0.5, bottom),
		Vector2(center_x - bottom_width * 0.5, bottom),
	]), color)

func draw_light_star(position: Vector2, radius: float, color: Color) -> void:
	draw_circle(position, 2.0, color)
	draw_line(position + Vector2(-radius, 0), position + Vector2(radius, 0), color, 1.0)
	draw_line(position + Vector2(0, -radius), position + Vector2(0, radius), color, 1.0)
