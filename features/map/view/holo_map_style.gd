class_name HoloMapStyle
extends RefCounted
## purpose: Shared holographic map drawing helpers: glow lines, dashed ring, hatched fills.


static func alpha(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, a)


static func glow_line(canvas: Control, p1: Vector2, p2: Vector2, col: Color, width: float, glow: float) -> void:
	var steps: int = 3
	for i: int in range(steps):
		var t: float = 1.0 - float(i) / float(steps)
		var layer_alpha: float = 0.18 * t
		var layer_width: float = width + glow * (1.0 + float(i))
		canvas.draw_line(p1, p2, alpha(col, layer_alpha), layer_width)
	canvas.draw_line(p1, p2, col, width)


static func dashed_circle(canvas: Control, center: Vector2, radius: float, col: Color, width: float, dash: float, gap: float, segments: int) -> void:
	var total: float = TAU * radius
	var step: float = total / float(segments)
	var accumulated: float = 0.0
	var drawing: bool = true
	var prev: Vector2 = center + Vector2(radius, 0.0)
	for i: int in range(1, segments + 1):
		var angle: float = TAU * float(i) / float(segments)
		var pt: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
		if drawing:
			canvas.draw_line(prev, pt, col, width)
		accumulated += step
		if drawing and accumulated >= dash:
			drawing = false
			accumulated = 0.0
		elif not drawing and accumulated >= gap:
			drawing = true
			accumulated = 0.0
		prev = pt


static func hatch_rect(rect: Rect2, spacing: float) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var x0: float = rect.position.x
	var y0: float = rect.position.y
	var x1: float = rect.end.x
	var y1: float = rect.end.y
	var d_min: float = y0 - x1
	var d_max: float = y1 - x0
	var step: float = spacing * sqrt(2.0)
	if step < 1.0:
		step = 1.0
	var d: float = d_min
	while d <= d_max:
		var pts: PackedVector2Array = _clip_diagonal(d, x0, y0, x1, y1)
		if pts.size() >= 2:
			out.append(pts)
		d += step
	return out


static func _clip_diagonal(d: float, x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	# line y = x + d; intersections with rect borders.
	var y_at_x0: float = x0 + d
	if y_at_x0 >= y0 and y_at_x0 <= y1:
		pts.append(Vector2(x0, y_at_x0))
	var y_at_x1: float = x1 + d
	if y_at_x1 >= y0 and y_at_x1 <= y1:
		pts.append(Vector2(x1, y_at_x1))
	var x_at_y0: float = y0 - d
	if x_at_y0 >= x0 and x_at_y0 <= x1:
		pts.append(Vector2(x_at_y0, y0))
	var x_at_y1: float = y1 - d
	if x_at_y1 >= x0 and x_at_y1 <= x1:
		pts.append(Vector2(x_at_y1, y1))
	return _dedupe_points(pts)


static func _dedupe_points(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var out: PackedVector2Array = PackedVector2Array([pts[0]])
	for i: int in range(1, pts.size()):
		if pts[i].distance_squared_to(out[out.size() - 1]) > 0.001:
			out.append(pts[i])
	return out
