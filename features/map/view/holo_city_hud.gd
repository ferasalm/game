class_name HoloCityHud
extends RefCounted
## purpose: Draws dark navy background, faint grid, corner brackets, compass and top captions.


static func draw_background_and_grid(canvas: CanvasItem, size: Vector2, look: HoloCityLook) -> void:
	var navy: Color = look.get_color("navy_fill")
	var navy_a: float = look.get_alpha("navy_fill")
	canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(navy.r, navy.g, navy.b, navy_a), true)

	var spacing: float = look.get_size("grid_spacing")
	var cyan: Color = look.get_color("cyan")
	var grid_col := Color(cyan.r, cyan.g, cyan.b, look.get_alpha("grid"))

	var x: float = spacing
	while x < size.x:
		canvas.draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_col, 1.0)
		x += spacing
	var y: float = spacing
	while y < size.y:
		canvas.draw_line(Vector2(0.0, y), Vector2(size.x, y), grid_col, 1.0)
		y += spacing


static func draw_overlay(canvas: CanvasItem, size: Vector2, look: HoloCityLook, font: Font) -> void:
	_draw_corner_brackets(canvas, size, look)
	_draw_compass(canvas, look, font)
	_draw_captions(canvas, look, font)


static func _draw_corner_brackets(canvas: CanvasItem, size: Vector2, look: HoloCityLook) -> void:
	var cyan: Color = look.get_color("cyan")
	var margin: float = look.get_size("corner_bracket_margin")
	var blen: float = look.get_size("corner_bracket_len")
	var bw: float = look.get_width("hud_bracket")

	# Top-left
	canvas.draw_line(Vector2(margin, margin + blen), Vector2(margin, margin), cyan, bw)
	canvas.draw_line(Vector2(margin, margin), Vector2(margin + blen, margin), cyan, bw)
	# Top-right
	canvas.draw_line(Vector2(size.x - margin - blen, margin), Vector2(size.x - margin, margin), cyan, bw)
	canvas.draw_line(Vector2(size.x - margin, margin), Vector2(size.x - margin, margin + blen), cyan, bw)
	# Bottom-left
	canvas.draw_line(Vector2(margin, size.y - margin - blen), Vector2(margin, size.y - margin), cyan, bw)
	canvas.draw_line(Vector2(margin, size.y - margin), Vector2(margin + blen, size.y - margin), cyan, bw)
	# Bottom-right
	canvas.draw_line(Vector2(size.x - margin - blen, size.y - margin), Vector2(size.x - margin, size.y - margin), cyan, bw)
	canvas.draw_line(Vector2(size.x - margin, size.y - margin - blen), Vector2(size.x - margin, size.y - margin), cyan, bw)


static func _draw_compass(canvas: CanvasItem, look: HoloCityLook, font: Font) -> void:
	var cx: float = look.get_size("compass_center_x")
	var cy: float = look.get_size("compass_center_y")
	var pos := Vector2(cx, cy)
	var r: float = look.get_size("compass_radius")
	var cyan: Color = look.get_color("cyan")

	look.draw_neon_circle(canvas, pos, r, cyan, 36)
	canvas.draw_arc(pos, r * 0.7, 0.0, TAU, 24, Color(cyan.r, cyan.g, cyan.b, 0.35), 1.0)

	var pointer := PackedVector2Array([
		pos + Vector2(0.0, -r + 2.0),
		pos + Vector2(4.0, -r * 0.3),
		pos + Vector2(-4.0, -r * 0.3)
	])
	canvas.draw_colored_polygon(pointer, cyan)
	canvas.draw_string(font, pos + Vector2(-5.0, 5.0), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, cyan)


static func _draw_captions(canvas: CanvasItem, look: HoloCityLook, font: Font) -> void:
	var cyan: Color = look.get_color("cyan")
	var tx: float = look.get_size("hud_title_x")
	var ty1: float = look.get_size("hud_title_y")
	var ty2: float = look.get_size("hud_coords_y")

	var title_text: String = Ui.text("MAP_METROPOLIS_SECTOR")
	var coords_text: String = Ui.text("MAP_COORDINATES")

	canvas.draw_string(font, Vector2(tx, ty1), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		int(look.get_size("font_hud_title")), cyan)
	canvas.draw_string(font, Vector2(tx, ty2), coords_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		int(look.get_size("font_hud_coords")), Color(cyan.r, cyan.g, cyan.b, 0.7))
