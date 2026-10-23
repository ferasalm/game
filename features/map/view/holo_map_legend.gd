class_name HoloMapLegend
extends Control
## purpose: Legend panel (260x260 at 80,140) showing marker icons and labels.

var _style: UiStyleDef
var _c_cyan: Color
var _c_good: Color
var _c_brass: Color
var _c_amber: Color


func _init() -> void:
	position = Vector2(80.0, 140.0)
	custom_minimum_size = Vector2(260.0, 260.0)
	size = Vector2(260.0, 260.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = Ui.style()
	_c_cyan = _style.colour(&"c_cyan")
	_c_good = _style.colour(&"c_good")
	_c_brass = _style.colour(&"c_brass")
	_c_amber = _style.colour(&"c_qam_amber")


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, _style.colour(&"c_glass_menu"), true)
	draw_rect(rect, _style.colour(&"c_brass_dim"), false, 2.0)
	var font: Font = Ui.theme().default_font
	draw_string(font, Vector2(24.0, 36.0), Ui.text("MAP_LEGEND"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, _style.colour(&"c_brass"))
	draw_line(Vector2(20.0, 48.0), Vector2(240.0, 48.0), _style.colour(&"c_brass_dim"), 1.0)

	_draw_player_row(Vector2(40.0, 80.0), font)
	_draw_npc_row(Vector2(40.0, 126.0), font)
	_draw_vendor_row(Vector2(40.0, 172.0), font)
	_draw_quest_row(Vector2(40.0, 218.0), font)


func _draw_player_row(pos: Vector2, font: Font) -> void:
	var pts := PackedVector2Array([
		Vector2(pos.x, pos.y - 10.0), Vector2(pos.x + 10.0, pos.y),
		Vector2(pos.x, pos.y + 10.0), Vector2(pos.x - 10.0, pos.y)
	])
	draw_colored_polygon(pts, _c_cyan)
	draw_string(font, Vector2(pos.x + 24.0, pos.y + 6.0), Ui.text("MAP_PLAYER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, _style.colour(&"c_text"))


func _draw_npc_row(pos: Vector2, font: Font) -> void:
	draw_arc(pos, 9.0, 0.0, TAU, 24, _c_good, 2.5)
	draw_string(font, Vector2(pos.x + 24.0, pos.y + 6.0), Ui.text("MAP_NPC"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, _style.colour(&"c_text"))


func _draw_vendor_row(pos: Vector2, font: Font) -> void:
	var cart := PackedVector2Array([
		Vector2(pos.x - 8.0, pos.y - 6.0), Vector2(pos.x + 8.0, pos.y - 6.0),
		Vector2(pos.x + 5.0, pos.y + 4.0), Vector2(pos.x - 5.0, pos.y + 4.0)
	])
	draw_colored_polygon(cart, _c_brass)
	draw_circle(Vector2(pos.x - 4.0, pos.y + 7.0), 2.0, _c_brass)
	draw_circle(Vector2(pos.x + 4.0, pos.y + 7.0), 2.0, _c_brass)
	draw_string(font, Vector2(pos.x + 24.0, pos.y + 6.0), Ui.text("MAP_VENDOR"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, _style.colour(&"c_text"))


func _draw_quest_row(pos: Vector2, font: Font) -> void:
	draw_line(Vector2(pos.x, pos.y - 9.0), Vector2(pos.x, pos.y + 2.0), _c_amber, 3.0)
	draw_circle(Vector2(pos.x, pos.y + 8.0), 2.0, _c_amber)
	draw_string(font, Vector2(pos.x + 24.0, pos.y + 6.0), Ui.text("MAP_QUEST"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, _style.colour(&"c_text"))
