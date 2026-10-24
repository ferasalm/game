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

	canvas.draw_line(Vector2(margin, margin + blen), Vector2(margin, margin), cyan, bw)
	canvas.draw_line(Vector2(margin, margin), Vector2(margin + blen, margin), cyan, bw)
	canvas.draw_line(Vector2(size.x - margin - blen, margin), Vector2(size.x - margin, margin), cyan, bw)
	canvas.draw_line(Vector2(size.x - margin, margin), Vector2(size.x - margin, margin + blen), cyan, bw)
	canvas.draw_line(Vector2(margin, size.y - margin - blen), Vector2(margin, size.y - margin), cyan, bw)
	canvas.draw_line(Vector2(margin, size.y - margin), Vector2(margin + blen, size.y - margin), cyan, bw)
	canvas.draw_line(Vector2(size.x - margin - blen, size.y - margin), Vector2(size.x - margin, size.y - margin), cyan, bw)
	canvas.draw_line(Vector2(size.x - margin, size.y - margin - blen), Vector2(size.x - margin, size.y - margin), cyan, bw)


static func _draw_compass(canvas: CanvasItem, look: HoloCityLook, font: Font) -> void:
	var pos: Vector2 = look.get_point("compass_center")
	var r: float = look.get_size("compass_radius")
	var cyan: Color = look.get_color("cyan")

	look.draw_neon_circle(canvas, pos, r, cyan, look.get_count("compass_segments"))
	canvas.draw_arc(pos, r * look.get_size("compass_inner_ratio"), 0.0, TAU,
		look.get_count("compass_inner_segments"), Color(cyan.r, cyan.g, cyan.b, look.get_alpha("compass_inner")), 1.0)

	var pw: float = look.get_size("compass_pointer_w")
	var pr: float = r * look.get_size("compass_pointer_ratio")
	var pointer := PackedVector2Array([
		pos + Vector2(0.0, -r + 2),
		pos + Vector2(pw, -pr),
		pos + Vector2(-pw, -pr)
	])
	canvas.draw_colored_polygon(pointer, cyan)
	canvas.draw_string(font, pos + look.get_point("compass_text_offset"), "N",
		HORIZONTAL_ALIGNMENT_CENTER, -1, int(look.get_size("compass_font_size")), cyan)


static func _draw_captions(canvas: CanvasItem, look: HoloCityLook, font: Font) -> void:
	var cyan: Color = look.get_color("cyan")
	var tpos: Vector2 = look.get_point("hud_title_pos")
	var cpos: Vector2 = look.get_point("hud_coords_pos")

	var title_text: String = Ui.text("MAP_METROPOLIS_SECTOR")
	var coords_text: String = Ui.text("MAP_COORDINATES")

	canvas.draw_string(font, tpos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		int(look.get_size("font_hud_title")), cyan)
	canvas.draw_string(font, cpos, coords_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		int(look.get_size("font_hud_coords")), Color(cyan.r, cyan.g, cyan.b, look.get_alpha("hud_coords")))
