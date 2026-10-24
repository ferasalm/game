class_name HoloMapCityPreview
extends Control
## purpose: Circular city map radar preview (300x300 at 1560,720) showing Sana'a district outlines.

const RADAR_MARGIN: float = 0.08

var _style: UiStyleDef
var _c_cyan: Color
var _c_brass: Color
var _districts: Array[CityDistrictDef] = []
var _features: Array[CityDistrictDef] = []
var _pins: Array[CityDistrictDef] = []
var _center: Vector2 = Vector2(150.0, 150.0)
var _radius: float = 120.0
var _scale: float = 0.0
var _offset: Vector2 = Vector2.ZERO
var _radial: Dictionary = {}


func _init() -> void:
	position = Vector2(1560.0, 720.0)
	custom_minimum_size = Vector2(300.0, 300.0)
	size = Vector2(300.0, 300.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = Ui.style()
	_c_cyan = _style.colour(&"c_cyan")
	_c_brass = _style.colour(&"c_brass")
	_center = size * 0.5
	_radius = minf(size.x, size.y) * 0.4
	_load_city_data()


func _load_city_data() -> void:
	_districts.clear()
	_features.clear()
	_pins.clear()
	for d_id: StringName in ContentDB.ids("city_district"):
		var def := ContentDB.get_def("city_district", d_id) as CityDistrictDef
		if def == null:
			continue
		match def.feature:
			&"district":
				_districts.append(def)
			&"area_pin":
				_pins.append(def)
			_:
				_features.append(def)
	_radial = HoloMapGeo.radial_params(_features, _pins)
	var rc: Vector2 = _radial["center"]
	var rk: float = float(_radial["k"])
	var rr: float = float(_radial["r"])
	var bounds: Rect2 = HoloMapGeo.city_bounds(_districts, _features, _pins, Rect2(Vector2.ZERO, Vector2.ONE), rc, rk, rr)
	var side: float = _radius * sqrt(2.0)
	var tr: Dictionary = HoloMapGeo.fit(bounds, Vector2(side, side), RADAR_MARGIN)
	_scale = float(tr.get("scale", 0.0))
	_offset = (tr.get("offset", Vector2.ZERO) as Vector2) + _center - Vector2(side, side) * 0.5


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
	var rc: Vector2 = _radial["center"]
	var rk: float = float(_radial["k"])
	var rr: float = float(_radial["r"])
	for d: CityDistrictDef in _districts:
		if d.id == &"al_saila" or d.id == &"zubairi":
			continue
		var pts: PackedVector2Array = HoloMapGeo.to_screen_polygon(d.polygon, _scale, _offset, rc, rk, rr)
		if pts.size() >= 3:
			var fill_color := Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.12 if d.is_old_city else 0.04)
			draw_colored_polygon(pts, fill_color)
			draw_polyline(pts, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.7), 1.5)
			draw_line(pts[-1], pts[0], Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.7), 1.5)
		if d.is_old_city:
			var c: Vector2 = HoloMapGeo.centroid(pts)
			draw_arc(c, 10.0, 0.0, TAU, 32, _c_cyan, 2.5)
	for f: CityDistrictDef in _features:
		if f.feature == &"line" and f.line.size() >= 2:
			var pts: PackedVector2Array = HoloMapGeo.to_screen_polyline(f.line, _scale, _offset, rc, rk, rr)
			draw_polyline(pts, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.7), 2.0)
