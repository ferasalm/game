class_name HoloMapMarkers
extends RefCounted
## purpose: Draw map marker icons (player, npc, vendor, quest) used by the area view.


static func draw_icon(canvas: Control, pos: Vector2, kind: StringName, colors: Dictionary) -> void:
	var col: Color = colors.get(kind, colors.get(&"default", Color.CYAN))
	canvas.draw_circle(pos, 22.0, HoloMapStyle.alpha(col, 0.22))
	match kind:
		&"player":
			_player(canvas, pos, colors.get(&"default", Color.CYAN))
		&"npc":
			canvas.draw_arc(pos, 16.0, 0.0, TAU, 32, col, 3.0)
		&"vendor":
			_vendor(canvas, pos, col)
		&"quest":
			canvas.draw_line(Vector2(pos.x, pos.y - 14.0), Vector2(pos.x, pos.y + 3.0), col, 4.0)
			canvas.draw_circle(Vector2(pos.x, pos.y + 12.0), 3.0, col)


static func _player(canvas: Control, pos: Vector2, col: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(pos.x, pos.y - 18.0), Vector2(pos.x + 18.0, pos.y),
		Vector2(pos.x, pos.y + 18.0), Vector2(pos.x - 18.0, pos.y)
	])
	canvas.draw_colored_polygon(pts, col)
	canvas.draw_polyline(pts, Color.WHITE, 1.5)


static func _vendor(canvas: Control, pos: Vector2, col: Color) -> void:
	var cart := PackedVector2Array([
		Vector2(pos.x - 12.0, pos.y - 9.0), Vector2(pos.x + 12.0, pos.y - 9.0),
		Vector2(pos.x + 8.0, pos.y + 6.0), Vector2(pos.x - 8.0, pos.y + 6.0)
	])
	canvas.draw_colored_polygon(cart, col)
	canvas.draw_circle(Vector2(pos.x - 6.0, pos.y + 11.0), 3.0, col)
	canvas.draw_circle(Vector2(pos.x + 6.0, pos.y + 11.0), 3.0, col)


static func draw_area_pin(canvas: Control, pos: Vector2, active: bool, reached: bool, pulse: float, col: Color) -> void:
	var alpha: float = 1.0 if reached else 0.35
	if active:
		var ring_r: float = 14.0 + pulse * 8.0
		canvas.draw_arc(pos, ring_r, 0.0, TAU, 32, HoloMapStyle.alpha(col, 0.5 * alpha), 2.5)
	var pts := PackedVector2Array([
		Vector2(pos.x, pos.y - 10.0), Vector2(pos.x + 7.0, pos.y),
		Vector2(pos.x, pos.y + 10.0), Vector2(pos.x - 7.0, pos.y)
	])
	canvas.draw_colored_polygon(pts, HoloMapStyle.alpha(col, alpha))
	canvas.draw_polyline(pts, HoloMapStyle.alpha(Color.WHITE, alpha), 1.0)
