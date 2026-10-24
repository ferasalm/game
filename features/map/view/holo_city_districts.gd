class_name HoloCityDistricts
extends RefCounted
## purpose: Draws Tahrir fan, Haddah blocks, Bayt Baws towers, al-Hasaba, ring road, Zubairi and Jabal Nuqum.


static func draw(canvas: CanvasItem, look: HoloCityLook, bounds: Rect2 = Rect2()) -> void:
	var clip_bounds: Rect2 = bounds
	if clip_bounds.size == Vector2.ZERO:
		clip_bounds = Rect2(Vector2.ZERO, Vector2(look.get_size("canvas_w"), look.get_size("canvas_h")))
	_draw_ring_road(canvas, look)
	_draw_tahrir_fan(canvas, look)
	_draw_haddah_blocks(canvas, look)
	_draw_bayt_baws_towers(canvas, look)
	_draw_al_hasaba(canvas, look)
	_draw_zubairi_street(canvas, look)
	_draw_jabal_nuqum(canvas, look, clip_bounds)


static func clip_polyline(pts: PackedVector2Array, bounds: Rect2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var max_x: float = bounds.end.x - 1.0
	var max_y: float = bounds.end.y - 1.0
	for p: Vector2 in pts:
		out.append(Vector2(
			clampf(p.x, bounds.position.x, max_x),
			clampf(p.y, bounds.position.y, max_y)
		))
	return out


static func _draw_tahrir_fan(canvas: CanvasItem, look: HoloCityLook) -> void:
	var center: Vector2 = look.get_point("old_city_center")
	var r_in: float = look.get_size("old_city_radius") + look.get_size("tahrir_inner_gap")
	var r_out: float = r_in + look.get_size("tahrir_depth")
	var col: Color = look.get_color("cyan")
	var a_start: float = look.get_size("tahrir_angle_start")
	var a_end: float = look.get_size("tahrir_angle_end")
	var spokes: int = look.get_count("tahrir_spokes")
	var arcs: int = look.get_count("tahrir_arcs")
	var grid_a: float = look.get_alpha("tahrir_grid")
	var glow_a: float = look.get_alpha("neon_mid")
	var glow_w: float = look.get_width("neon_mid")
	var grid_w: float = look.get_width("grid_line")
	var segs: int = look.get_count("tahrir_segments")

	for i: int in range(spokes):
		var a: float = lerpf(a_start, a_end, float(i) / float(spokes - 1))
		var dir := Vector2(cos(a), sin(a))
		canvas.draw_line(center + dir * r_in, center + dir * r_out, Color(col.r, col.g, col.b, glow_a), glow_w)
		canvas.draw_line(center + dir * r_in, center + dir * r_out, Color(col.r, col.g, col.b, grid_a), grid_w)
	for j: int in range(arcs):
		var r: float = lerpf(r_in, r_out, float(j) / float(arcs - 1))
		canvas.draw_arc(center, r, a_start, a_end, segs, Color(col.r, col.g, col.b, glow_a), glow_w)
		canvas.draw_arc(center, r, a_start, a_end, segs, Color(col.r, col.g, col.b, grid_a), grid_w)
	look.draw_neon_arc(canvas, center, r_in, a_start, a_end, segs, col)
	look.draw_neon_arc(canvas, center, r_out, a_start, a_end, segs, col)
	look.draw_neon_line(canvas, center + Vector2(cos(a_start), sin(a_start)) * r_in,
		center + Vector2(cos(a_start), sin(a_start)) * r_out, col)
	look.draw_neon_line(canvas, center + Vector2(cos(a_end), sin(a_end)) * r_in,
		center + Vector2(cos(a_end), sin(a_end)) * r_out, col)


static func _draw_haddah_blocks(canvas: CanvasItem, look: HoloCityLook) -> void:
	var col: Color = look.get_color("green")
	var fill_a: float = look.get_alpha("haddah_fill")
	var fill_col := Color(col.r, col.g, col.b, fill_a)
	var blocks: Array[PackedVector2Array] = look.get_blocks("haddah_blocks")
	for b: PackedVector2Array in blocks:
		canvas.draw_colored_polygon(b, fill_col)
		look.draw_neon_polyline(canvas, b, col, true)


static func _draw_bayt_baws_towers(canvas: CanvasItem, look: HoloCityLook) -> void:
	var col: Color = look.get_color("cyan")
	var base_pos: Vector2 = look.get_point("bayt_baws_base")
	var widths: PackedFloat32Array = look.get_floats("bayt_baws_widths")
	var heights: PackedFloat32Array = look.get_floats("bayt_baws_heights")
	var gap: float = look.get_size("bayt_baws_gap")
	var cur_x: float = base_pos.x

	for i: int in range(widths.size()):
		var w: float = widths[i]
		var h: float = heights[i]
		var rect := Rect2(cur_x, base_pos.y - h, w, h)
		canvas.draw_rect(rect, Color(col.r, col.g, col.b, look.get_alpha("bayt_baws_bg")))
		look.draw_neon_polyline(canvas, PackedVector2Array([
			rect.position, Vector2(rect.end.x, rect.position.y),
			rect.end, Vector2(rect.position.x, rect.end.y)
		]), col, true)
		var cx_scale: float = look.get_size("bayt_baws_core_scale_x")
		var cy_scale: float = look.get_size("bayt_baws_core_scale_y")
		var cw_scale: float = look.get_size("bayt_baws_core_w_scale")
		var ch_scale: float = look.get_size("bayt_baws_core_h_scale")
		var core := Rect2(cur_x + w * cx_scale, base_pos.y - h * cy_scale, w * cw_scale, h * ch_scale)
		canvas.draw_rect(core, Color.WHITE)
		cur_x += w + gap


static func _draw_al_hasaba(canvas: CanvasItem, look: HoloCityLook) -> void:
	var teal: Color = look.get_color("teal")
	var yellow: Color = look.get_color("yellow")
	var outline: PackedVector2Array = look.get_points("al_hasaba_outline")
	canvas.draw_colored_polygon(outline, Color(teal.r, teal.g, teal.b, look.get_alpha("al_hasaba_fill")))
	look.draw_neon_polyline(canvas, outline, teal, true)

	var rw_pts: PackedVector2Array = look.get_points("al_hasaba_runway")
	if rw_pts.size() > 1:
		canvas.draw_line(rw_pts[0], rw_pts[1], Color(yellow.r, yellow.g, yellow.b,
			look.get_alpha("neon_wide")), look.get_width("runway_wide"))
		canvas.draw_line(rw_pts[0], rw_pts[1], Color(yellow.r, yellow.g, yellow.b,
			look.get_alpha("neon_mid")), look.get_width("runway_mid"))
		canvas.draw_line(rw_pts[0], rw_pts[1], Color.WHITE, look.get_width("runway_core"))


static func _draw_zubairi_street(canvas: CanvasItem, look: HoloCityLook) -> void:
	var col: Color = look.get_color("cyan")
	var pts: PackedVector2Array = look.get_points("zubairi_pts")
	look.draw_neon_polyline(canvas, pts, col, false)


static func _draw_jabal_nuqum(canvas: CanvasItem, look: HoloCityLook, bounds: Rect2) -> void:
	var center: Vector2 = look.get_point("jabal_nuqum_center")
	var violet: Color = look.get_color("violet")
	var num_contours: int = look.get_count("jabal_nuqum_contours")
	var noise := FastNoiseLite.new()
	noise.seed = look.get_seed("nuqum_seed")
	noise.frequency = look.get_size("nuqum_noise_freq")
	var r_min: float = look.get_size("nuqum_r_min")
	var r_max: float = look.get_size("nuqum_r_max")
	var steps: int = look.get_count("nuqum_steps")
	var angle_scale: float = look.get_size("nuqum_noise_angle_scale")
	var k_step: float = look.get_size("nuqum_noise_k_step")
	var amp_base: float = look.get_size("nuqum_noise_amp_base")
	var amp_scale: float = look.get_size("nuqum_noise_amp_scale")
	var line_w: float = look.get_width("nuqum_line")

	for k: int in range(num_contours):
		var t: float = float(k) / float(num_contours - 1)
		var r_base: float = lerpf(r_min, r_max, t)
		var a: float = lerpf(look.get_alpha("contour_inner"), look.get_alpha("contour_outer"), t)
		var pts := PackedVector2Array()
		for step: int in range(steps):
			var angle: float = TAU * float(step) / float(steps)
			var w: float = noise.get_noise_2d(cos(angle) * angle_scale + float(k) * k_step,
				sin(angle) * angle_scale) * (amp_base + t * amp_scale)
			pts.append(center + Vector2(cos(angle), sin(angle)) * (r_base + w))
		pts.append(pts[0])
		var clipped: PackedVector2Array = clip_polyline(pts, bounds)
		canvas.draw_polyline(clipped, Color(violet.r, violet.g, violet.b, a), line_w)


static func _draw_ring_road(canvas: CanvasItem, look: HoloCityLook) -> void:
	var blue: Color = look.get_color("blue")
	var magenta: Color = look.get_color("magenta")
	var r_roundabout: float = look.get_size("roundabout_r")
	var pts_base: PackedVector2Array = look.get_points("ring_road_pts")
	var offset: float = look.get_size("ring_road_offset")
	var loop_blue := _offset_loop(pts_base, -offset)
	var loop_mag := _offset_loop(pts_base, offset)
	look.draw_neon_polyline(canvas, loop_blue, blue, true)
	look.draw_neon_polyline(canvas, loop_mag, magenta, true)
	var roundabouts: PackedVector2Array = look.get_points("ring_road_roundabouts")
	var rb_segs: int = look.get_count("roundabout_segments")
	if roundabouts.size() > 1:
		look.draw_neon_circle(canvas, roundabouts[0], r_roundabout, blue, rb_segs)
		look.draw_neon_circle(canvas, roundabouts[1], r_roundabout, magenta, rb_segs)


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
