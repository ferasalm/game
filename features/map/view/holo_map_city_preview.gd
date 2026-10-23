class_name HoloMapCityPreview
extends Control
## purpose: Circular city map radar preview (300x300 at 1560,720) showing Sana'a district outlines.

var _style: UiStyleDef
var _c_cyan: Color
var _c_brass: Color
var _districts: Array[CityDistrictDef] = []
var _center: Vector2 = Vector2(150.0, 150.0)
var _radius: float = 120.0


func _init() -> void:
	position = Vector2(1560.0, 720.0)
	custom_minimum_size = Vector2(300.0, 300.0)
	size = Vector2(300.0, 300.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = Ui.style()
	_c_cyan = _style.colour(&"c_cyan")
	_c_brass = _style.colour(&"c_brass")
	_load_districts()


func _load_districts() -> void:
	_districts.clear()
	for d_id: StringName in ContentDB.ids("city_district"):
		var def := ContentDB.get_def("city_district", d_id) as CityDistrictDef
		if def != null:
			_districts.append(def)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, _style.colour(&"c_glass_menu"), true)
	draw_rect(rect, _style.colour(&"c_brass_dim"), false, 2.0)

	var font: Font = Ui.theme().default_font
	draw_string(font, Vector2(20.0, 28.0), "SANA'A DISTRICTS", HORIZONTAL_ALIGNMENT_CENTER, 260, 18, _c_cyan)
	_draw_radar_grid()
	_draw_districts()
	draw_string(font, Vector2(10.0, 284.0), "PRESS [Y] FOR FULL CITY MAP", HORIZONTAL_ALIGNMENT_CENTER, 280, 13, _style.colour(&"c_muted"))


func _draw_radar_grid() -> void:
	draw_circle(_center, _radius, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.05))
	draw_arc(_center, _radius, 0.0, TAU, 48, _c_cyan, 2.0)
	draw_arc(_center, _radius * 0.65, 0.0, TAU, 36, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.3), 1.0)
	draw_arc(_center, _radius * 0.35, 0.0, TAU, 24, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.3), 1.0)
	draw_line(_center - Vector2(_radius, 0.0), _center + Vector2(_radius, 0.0), Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.2), 1.0)
	draw_line(_center - Vector2(0.0, _radius), _center + Vector2(0.0, _radius), Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.2), 1.0)


func _draw_districts() -> void:
	var scale_factor: float = _radius * 0.85 / 1000.0
	for d: CityDistrictDef in _districts:
		var pts := PackedVector2Array()
		for pt: Vector2 in d.polygon:
			pts.append(_center + pt * scale_factor)
		if pts.size() >= 3:
			var fill_color := Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.12 if d.is_old_city else 0.04)
			draw_colored_polygon(pts, fill_color)
			draw_polyline(pts, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.7), 1.5)
			draw_line(pts[-1], pts[0], Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.7), 1.5)
		if d.is_old_city:
			draw_arc(_center, 18.0, 0.0, TAU, 32, _c_cyan, 2.5)
