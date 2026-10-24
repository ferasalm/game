class_name HoloCityOldTown
extends RefCounted
## purpose: Draws Old City disc, seeded maze rings, Bab al-Yaman reticle, al-Saila channel and area pin.


static func draw_background_disc(canvas: CanvasItem, look: HoloCityLook) -> void:
	var center: Vector2 = look.get_point("old_city_center")
	var radius: float = look.get_size("old_city_radius")
	var disc_col: Color = look.get_color("old_city_disc")
	var disc_a: float = look.get_alpha("old_city_fill")
	canvas.draw_circle(center, radius, Color(disc_col.r, disc_col.g, disc_col.b, disc_a))


static func draw(canvas: CanvasItem, look: HoloCityLook, pulse: float, pin_active: bool) -> void:
	var center: Vector2 = look.get_point("old_city_center")
	var radius: float = look.get_size("old_city_radius")
	var orange: Color = look.get_color("old_city")
	var maze_orange: Color = look.get_color("old_city_maze")
	var cyan: Color = look.get_color("cyan")

	_draw_rim_glow(canvas, center, radius, orange, look)
	look.draw_neon_circle(canvas, center, radius, orange, look.get_count("old_city_segments"))
	_draw_maze(canvas, center, radius, maze_orange, look)
	_draw_saila_channel(canvas, center, radius, cyan, look)
	_draw_bab_al_yaman(canvas, center, radius, cyan, look, pulse)
	_draw_pin(canvas, center, radius, pin_active, pulse, cyan, look)


static func _draw_rim_glow(canvas: CanvasItem, center: Vector2, radius: float, col: Color, look: HoloCityLook) -> void:
	var glow_col := Color(col.r, col.g, col.b, look.get_alpha("old_city_glow"))
	canvas.draw_circle(center, radius, glow_col)


static func _draw_maze(canvas: CanvasItem, center: Vector2, radius: float, col: Color, look: HoloCityLook) -> void:
	var num_rings: int = look.get_count("old_city_rings")
	var rng := RandomNumberGenerator.new()
	rng.seed = look.get_seed("maze_seed")
	var gap_prob: float = look.get_size("maze_gap_prob")
	var gap_a: float = look.get_size("maze_gap_angle")
	var rad_prob: float = look.get_size("maze_radial_prob")
	var s_base: int = look.get_count("maze_sectors_base")
	var s_step: int = look.get_count("maze_sectors_step")
	var arc_segs: int = look.get_count("maze_arc_segments")

	for ring_idx: int in range(num_rings):
		var r: float = radius * float(ring_idx + 1) / float(num_rings + 1)
		var sectors: int = s_base + ring_idx * s_step
		for s: int in range(sectors):
			var a0: float = TAU * float(s) / float(sectors)
			var a1: float = TAU * float(s + 1) / float(sectors)
			if rng.randf() > gap_prob:
				look.draw_maze_arc(canvas, center, r, a0 + gap_a, a1 - gap_a, arc_segs, col)
			if ring_idx > 0 and rng.randf() < rad_prob:
				var prev_r: float = radius * float(ring_idx) / float(num_rings + 1)
				var dir := Vector2(cos(a0), sin(a0))
				look.draw_maze_line(canvas, center + dir * prev_r, center + dir * r, col)


static func _draw_saila_channel(canvas: CanvasItem, center: Vector2, radius: float, col: Color, look: HoloCityLook) -> void:
	var rel_pts: PackedVector2Array = look.get_points("saila_pts_relative")
	var pts := PackedVector2Array()
	for p: Vector2 in rel_pts:
		pts.append(center + Vector2(p.x, radius * p.y))
	look.draw_neon_polyline(canvas, pts, col, false)


static func _draw_bab_al_yaman(canvas: CanvasItem, center: Vector2, radius: float, col: Color, look: HoloCityLook,
		pulse: float) -> void:
	var pos: Vector2 = center + Vector2(radius, 0.0)
	var p_scale: float = look.get_size("reticle_pulse_scale")
	var p_factor: float = 1.0 + p_scale * pulse
	var r_outer: float = look.get_size("reticle_outer_r") * p_factor
	var r_mid: float = look.get_size("reticle_mid_r") * p_factor
	var r_inner: float = look.get_size("reticle_inner_r") * p_factor
	var segs: int = look.get_count("reticle_segments")

	look.draw_neon_circle(canvas, pos, r_outer, col, segs)
	look.draw_neon_circle(canvas, pos, r_mid, col, segs)
	look.draw_neon_circle(canvas, pos, r_inner, col, segs)
	var clen: float = look.get_size("reticle_cross_len") * p_factor
	look.draw_neon_line(canvas, pos - Vector2(clen, 0.0), pos + Vector2(clen, 0.0), col)
	look.draw_neon_line(canvas, pos - Vector2(0.0, clen), pos + Vector2(0.0, clen), col)


static func _draw_pin(canvas: CanvasItem, center: Vector2, radius: float, active: bool, pulse: float,
		col: Color, look: HoloCityLook) -> void:
	var pin_pos: Vector2 = center + look.get_point("pin_offset")
	var pr: float = look.get_size("pin_reticle_r")
	var pulse_r: float = pr * (1.0 + look.get_size("pin_pulse_scale") * pulse)
	var alpha_pulse: float = 0.5 + 0.5 * (1.0 - pulse)
	var ring_col := Color(col.r, col.g, col.b, alpha_pulse if active else look.get_alpha("pin_inactive"))
	canvas.draw_arc(pin_pos, pulse_r, 0.0, TAU, look.get_count("pin_segments"), ring_col, look.get_width("pin_ring"))
	var dsz: float = look.get_size("pin_diamond_size")
	var diamond := PackedVector2Array([
		pin_pos + Vector2(0.0, -dsz),
		pin_pos + Vector2(dsz, 0.0),
		pin_pos + Vector2(0.0, dsz),
		pin_pos + Vector2(-dsz, 0.0)
	])
	canvas.draw_colored_polygon(diamond, Color.WHITE if active else col)
	look.draw_neon_polyline(canvas, diamond, col, true)
