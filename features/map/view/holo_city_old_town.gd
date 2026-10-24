class_name HoloCityOldTown
extends RefCounted
## purpose: Draws Old City disc, seeded maze rings, Bab al-Yaman reticle, al-Saila channel and area pin.


static func draw(canvas: CanvasItem, look: HoloCityLook, pulse: float, pin_active: bool) -> void:
	var center := Vector2(760.0, 420.0)
	var radius: float = look.get_size("old_city_radius")
	var orange: Color = look.get_color("old_city")
	var cyan: Color = look.get_color("cyan")

	_draw_gradient_disc(canvas, center, radius, orange, look.get_alpha("old_city_fill"))
	look.draw_neon_circle(canvas, center, radius, orange, 64)
	_draw_maze(canvas, center, radius, orange, look)
	_draw_saila_channel(canvas, center, radius, cyan, look)
	_draw_bab_al_yaman(canvas, center, radius, cyan, look)
	_draw_pin(canvas, center, radius, pin_active, pulse, cyan, look)


static func _draw_gradient_disc(canvas: CanvasItem, center: Vector2, radius: float, col: Color, max_alpha: float) -> void:
	var steps: int = 12
	for i: int in range(steps):
		var t: float = 1.0 - float(i) / float(steps)
		var r: float = radius * t
		var a: float = max_alpha * (0.2 + 0.8 * (1.0 - t))
		canvas.draw_circle(center, r, Color(col.r, col.g, col.b, a))


static func _draw_maze(canvas: CanvasItem, center: Vector2, radius: float, col: Color, look: HoloCityLook) -> void:
	var num_rings: int = look.get_count("old_city_rings")
	var line_w: float = look.get_width("maze_line")
	var rng := RandomNumberGenerator.new()
	rng.seed = look.get_seed("maze_seed")
	var maze_col := Color(col.r, col.g, col.b, look.get_alpha("neon_core"))

	for ring_idx: int in range(num_rings):
		var r: float = radius * float(ring_idx + 1) / float(num_rings + 1)
		var sectors: int = 18 + ring_idx * 4
		for s: int in range(sectors):
			var a0: float = TAU * float(s) / float(sectors)
			var a1: float = TAU * float(s + 1) / float(sectors)
			if rng.randf() > 0.28:
				canvas.draw_arc(center, r, a0 + 0.04, a1 - 0.04, 6, maze_col, line_w)
			if ring_idx > 0 and rng.randf() < 0.22:
				var prev_r: float = radius * float(ring_idx) / float(num_rings + 1)
				var dir := Vector2(cos(a0), sin(a0))
				canvas.draw_line(center + dir * prev_r, center + dir * r, maze_col, line_w)


static func _draw_saila_channel(canvas: CanvasItem, center: Vector2, radius: float, col: Color, look: HoloCityLook) -> void:
	var pts := PackedVector2Array([
		center + Vector2(-40.0, -radius * 0.96),
		center + Vector2(-48.0, -radius * 0.5),
		center + Vector2(-55.0, 0.0),
		center + Vector2(-42.0, radius * 0.5),
		center + Vector2(-30.0, radius * 0.96)
	])
	look.draw_neon_polyline(canvas, pts, col, false)


static func _draw_bab_al_yaman(canvas: CanvasItem, center: Vector2, radius: float, col: Color, look: HoloCityLook) -> void:
	var rim_angle: float = 0.95
	var pos: Vector2 = center + Vector2(cos(rim_angle), sin(rim_angle)) * radius
	var r_outer: float = look.get_size("reticle_outer_r")
	var r_mid: float = look.get_size("reticle_mid_r")
	var r_inner: float = look.get_size("reticle_inner_r")

	look.draw_neon_circle(canvas, pos, r_outer, col, 24)
	look.draw_neon_circle(canvas, pos, r_mid, col, 16)
	canvas.draw_circle(pos, r_inner, col)
	canvas.draw_line(pos - Vector2(r_outer + 8.0, 0.0), pos + Vector2(r_outer + 8.0, 0.0), col, 1.5)
	canvas.draw_line(pos - Vector2(0.0, r_outer + 8.0), pos + Vector2(0.0, r_outer + 8.0), col, 1.5)


static func _draw_pin(canvas: CanvasItem, center: Vector2, radius: float, active: bool, pulse: float,
		col: Color, look: HoloCityLook) -> void:
	var pin_pos: Vector2 = center + Vector2(21.0, -28.0)
	var pr: float = look.get_size("pin_reticle_r")
	var pulse_r: float = pr * (1.0 + 0.4 * pulse)
	var alpha_pulse: float = 0.5 + 0.5 * (1.0 - pulse)

	var ring_col := Color(col.r, col.g, col.b, alpha_pulse if active else 0.3)
	canvas.draw_arc(pin_pos, pulse_r, 0.0, TAU, 32, ring_col, 2.0)
	var diamond := PackedVector2Array([
		pin_pos + Vector2(0.0, -7.0),
		pin_pos + Vector2(7.0, 0.0),
		pin_pos + Vector2(0.0, 7.0),
		pin_pos + Vector2(-7.0, 0.0)
	])
	canvas.draw_colored_polygon(diamond, Color.WHITE if active else col)
	look.draw_neon_polyline(canvas, diamond, col, true)
