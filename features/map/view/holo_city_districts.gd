class_name HoloCityDistricts
extends RefCounted
## purpose: Draws Tahrir fan, Haddah blocks, Bayt Baws towers, al-Hasaba, ring road, Zubairi and Jabal Nuqum.


static func draw(canvas: CanvasItem, look: HoloCityLook) -> void:
	_draw_ring_road(canvas, look)
	_draw_tahrir_fan(canvas, look)
	_draw_haddah_blocks(canvas, look)
	_draw_bayt_baws_towers(canvas, look)
	_draw_al_hasaba(canvas, look)
	_draw_zubairi_street(canvas, look)
	_draw_jabal_nuqum(canvas, look)


static func _draw_tahrir_fan(canvas: CanvasItem, look: HoloCityLook) -> void:
	var center := Vector2(760.0, 420.0)
	var r_in: float = look.get_size("old_city_radius") + 15.0
	var r_out: float = r_in + 220.0
	var col: Color = look.get_color("cyan")
	var a_start: float = 2.0
	var a_end: float = 4.28
	var spokes: int = look.get_count("tahrir_spokes")
	var arcs: int = look.get_count("tahrir_arcs")

	for i: int in range(spokes):
		var a: float = lerpf(a_start, a_end, float(i) / float(spokes - 1))
		var dir := Vector2(cos(a), sin(a))
		canvas.draw_line(center + dir * r_in, center + dir * r_out, Color(col.r, col.g, col.b, 0.45), 1.0)
	for j: int in range(arcs):
		var r: float = lerpf(r_in, r_out, float(j) / float(arcs - 1))
		canvas.draw_arc(center, r, a_start, a_end, 32, Color(col.r, col.g, col.b, 0.45), 1.0)
	look.draw_neon_arc(canvas, center, r_in, a_start, a_end, 32, col)
	look.draw_neon_arc(canvas, center, r_out, a_start, a_end, 32, col)
	look.draw_neon_line(canvas, center + Vector2(cos(a_start), sin(a_start)) * r_in,
		center + Vector2(cos(a_start), sin(a_start)) * r_out, col)
	look.draw_neon_line(canvas, center + Vector2(cos(a_end), sin(a_end)) * r_in,
		center + Vector2(cos(a_end), sin(a_end)) * r_out, col)


static func _draw_haddah_blocks(canvas: CanvasItem, look: HoloCityLook) -> void:
	var col: Color = look.get_color("green")
	var fill_a: float = look.get_alpha("haddah_fill")
	var fill_col := Color(col.r, col.g, col.b, fill_a)
	var blocks: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(380, 580), Vector2(460, 570), Vector2(450, 630), Vector2(370, 625)]),
		PackedVector2Array([Vector2(470, 568), Vector2(560, 560), Vector2(550, 620), Vector2(460, 628)]),
		PackedVector2Array([Vector2(365, 635), Vector2(450, 640), Vector2(440, 705), Vector2(350, 695)]),
		PackedVector2Array([Vector2(460, 638), Vector2(550, 630), Vector2(540, 700), Vector2(450, 710)]),
		PackedVector2Array([Vector2(560, 625), Vector2(620, 620), Vector2(615, 680), Vector2(550, 685)])
	]
	for b: PackedVector2Array in blocks:
		canvas.draw_colored_polygon(b, fill_col)
		look.draw_neon_polyline(canvas, b, col, true)


static func _draw_bayt_baws_towers(canvas: CanvasItem, look: HoloCityLook) -> void:
	var col: Color = look.get_color("cyan")
	var base_x: float = 680.0
	var widths: Array[float] = [20.0, 24.0, 28.0, 22.0, 18.0]
	var heights: Array[float] = [75.0, 105.0, 120.0, 95.0, 70.0]
	var cur_x: float = base_x

	for i: int in range(widths.size()):
		var w: float = widths[i]
		var h: float = heights[i]
		var rect := Rect2(cur_x, 750.0 - h, w, h)
		canvas.draw_rect(rect, Color(col.r, col.g, col.b, 0.25))
		look.draw_neon_polyline(canvas, PackedVector2Array([
			rect.position, Vector2(rect.end.x, rect.position.y),
			rect.end, Vector2(rect.position.x, rect.end.y)
		]), col, true)
		var core := Rect2(cur_x + w * 0.35, 750.0 - h * 0.85, w * 0.3, h * 0.7)
		canvas.draw_rect(core, Color.WHITE)
		cur_x += w + 6.0


static func _draw_al_hasaba(canvas: CanvasItem, look: HoloCityLook) -> void:
	var teal: Color = look.get_color("teal")
	var yellow: Color = look.get_color("yellow")
	var outline := PackedVector2Array([
		Vector2(460, 110), Vector2(740, 100), Vector2(770, 160),
		Vector2(650, 200), Vector2(440, 180)
	])
	canvas.draw_colored_polygon(outline, Color(teal.r, teal.g, teal.b, 0.15))
	look.draw_neon_polyline(canvas, outline, teal, true)
	var rw_from := Vector2(490.0, 145.0)
	var rw_to := Vector2(720.0, 135.0)
	canvas.draw_line(rw_from, rw_to, Color(yellow.r, yellow.g, yellow.b, look.get_alpha("neon_wide")), 12.0)
	canvas.draw_line(rw_from, rw_to, Color(yellow.r, yellow.g, yellow.b, look.get_alpha("neon_mid")), 6.0)
	canvas.draw_line(rw_from, rw_to, Color.WHITE, 2.0)


static func _draw_zubairi_street(canvas: CanvasItem, look: HoloCityLook) -> void:
	var col: Color = look.get_color("cyan")
	var pts := PackedVector2Array([Vector2(60, 480), Vector2(250, 480), Vector2(480, 490), Vector2(580, 470)])
	look.draw_neon_polyline(canvas, pts, col, false)


static func _draw_jabal_nuqum(canvas: CanvasItem, look: HoloCityLook) -> void:
	var center := Vector2(1060.0, 400.0)
	var violet: Color = look.get_color("violet")
	var num_contours: int = look.get_count("jabal_nuqum_contours")
	var noise := FastNoiseLite.new()
	noise.seed = look.get_seed("nuqum_seed")
	noise.frequency = 0.04

	for k: int in range(num_contours):
		var t: float = float(k) / float(num_contours - 1)
		var r_base: float = lerpf(35.0, 230.0, t)
		var a: float = lerpf(look.get_alpha("contour_inner"), look.get_alpha("contour_outer"), t)
		var pts := PackedVector2Array()
		for step: int in range(36):
			var angle: float = TAU * float(step) / 36.0
			var w: float = noise.get_noise_2d(cos(angle) * 100.0 + k * 15.0, sin(angle) * 100.0) * (12.0 + t * 24.0)
			pts.append(center + Vector2(cos(angle), sin(angle)) * (r_base + w))
		pts.append(pts[0])
		canvas.draw_polyline(pts, Color(violet.r, violet.g, violet.b, a), 1.5)


static func _draw_ring_road(canvas: CanvasItem, look: HoloCityLook) -> void:
	var blue: Color = look.get_color("blue")
	var magenta: Color = look.get_color("magenta")
	var r_roundabout: float = look.get_size("roundabout_r")
	var pts_base: PackedVector2Array = [
		Vector2(190, 420), Vector2(220, 260), Vector2(360, 130), Vector2(560, 60),
		Vector2(780, 70), Vector2(930, 160), Vector2(970, 320), Vector2(960, 520),
		Vector2(880, 680), Vector2(740, 760), Vector2(520, 750), Vector2(340, 690),
		Vector2(210, 580)
	]
	var loop_blue := _offset_loop(pts_base, -3.0)
	var loop_mag := _offset_loop(pts_base, 3.0)
	look.draw_neon_polyline(canvas, loop_blue, blue, true)
	look.draw_neon_polyline(canvas, loop_mag, magenta, true)
	look.draw_neon_circle(canvas, Vector2(190, 480), r_roundabout, blue, 24)
	look.draw_neon_circle(canvas, Vector2(620, 755), r_roundabout, magenta, 24)


static func _offset_loop(pts: PackedVector2Array, dist: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n: int = pts.size()
	for i: int in range(n):
		var p0: Vector2 = pts[(i - 1 + n) % n]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var tangent: Vector2 = (p2 - p0).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		out.append(p1 + normal * dist)
	return out
