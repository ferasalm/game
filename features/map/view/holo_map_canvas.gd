class_name HoloMapCanvas
extends Control
## purpose: 1200x800 holographic map canvas: rooftop floor plan or full city map with cyan glow and scanlines.

enum Mode { AREA, CITY }

const _CYAN: Color = Color("#23E6F0")
const _CITY_MARGIN: float = 0.08

var mode: Mode = Mode.AREA
var player_world_pos: Vector3 = Vector3.ZERO
var area_def: AreaDef = null
var flags: Dictionary = {}
var pulse_time: float = 0.0

var _style: UiStyleDef
var _c_cyan: Color
var _c_good: Color
var _c_brass: Color
var _c_amber: Color
var _plan: Dictionary = {}
var _fit: Dictionary = {}
var _markers: Array[Dictionary] = []
var _districts: Array[CityDistrictDef] = []
var _features: Array[CityDistrictDef] = []
var _area_pins: Array[CityDistrictDef] = []
var _scanlines: ColorRect
var _city_scale: float = 0.0
var _city_offset: Vector2 = Vector2.ZERO


func _init() -> void:
	position = Vector2(360.0, 140.0)
	custom_minimum_size = Vector2(1200.0, 800.0)
	size = Vector2(1200.0, 800.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = Ui.style()
	_c_cyan = _CYAN
	_c_good = _style.colour(&"c_good")
	_c_brass = _style.colour(&"c_brass")
	_c_amber = _style.colour(&"c_qam_amber")
	_setup_scanlines()
	_load_city_data()


func _setup_scanlines() -> void:
	_scanlines = ColorRect.new()
	_scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://features/map/view/holo_scan.gdshader")
	_scanlines.material = mat
	add_child(_scanlines)


func _load_city_data() -> void:
	_districts.clear()
	_features.clear()
	_area_pins.clear()
	for d_id: StringName in ContentDB.ids("city_district"):
		var d := ContentDB.get_def("city_district", d_id) as CityDistrictDef
		if d == null:
			continue
		match d.feature:
			&"district":
				_districts.append(d)
			&"area_pin":
				_area_pins.append(d)
			_:
				_features.append(d)


func refresh_plan() -> void:
	if area_def == null:
		return
	_plan = MapPlan.plan(area_def)
	_fit = MapPlan.fit(_plan, Rect2(Vector2.ZERO, size))
	var marker_defs: Array[MapMarkerDef] = []
	for m_id: StringName in ContentDB.ids("map_marker"):
		var m := ContentDB.get_def("map_marker", m_id) as MapMarkerDef
		if m != null:
			marker_defs.append(m)
	_markers = MapPlan.markers(area_def, marker_defs, flags)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, _style.colour(&"c_glass_menu"), true)
	draw_rect(rect, HoloMapStyle.alpha(_c_cyan, 0.4), false, 2.0)
	if mode == Mode.AREA:
		_draw_area_plan()
	else:
		_draw_city_map()


func _draw_area_plan() -> void:
	if _plan.is_empty() or not _fit.has("scale"):
		return
	var colors := {
		&"default": _c_cyan, &"npc": _c_good, &"vendor": _c_brass, &"quest": _c_amber,
		&"muted": _style.colour(&"c_muted"),
	}
	HoloMapAreaView.draw(self, _plan, _fit, _markers, player_world_pos, colors, Ui.theme().default_font)


func _draw_city_map() -> void:
	_ensure_city_fit()
	var font: Font = Ui.theme().default_font
	var flick: Dictionary = _flicker()
	var pulse: float = sin(pulse_time * TAU / maxf(float(flick["period"]), 0.1)) * 0.5 + 0.5
	var flicker: float = float(flick["base"]) + pulse * float(flick["amplitude"])
	var labels: Array[HoloMapLabel] = city_label_set(font)

	for d: CityDistrictDef in _districts:
		var pts := HoloMapGeo.to_screen_polygon(d.polygon, _city_scale, _city_offset)
		if pts.size() < 3:
			continue
		draw_colored_polygon(pts, HoloMapStyle.alpha(_c_cyan, 0.18 if d.is_old_city else 0.06))
		HoloMapStyle.glow_line(self, pts[-1], pts[0], _c_cyan, 2.0, 4.0)
		for i: int in range(pts.size() - 1):
			HoloMapStyle.glow_line(self, pts[i], pts[i + 1], _c_cyan, 2.0, 4.0)
		if d.is_old_city:
			var c: Vector2 = HoloMapGeo.centroid(pts)
			draw_arc(c, 30.0 + pulse * 10.0, 0.0, TAU, 36, HoloMapStyle.alpha(_c_cyan, 0.6 + 0.4 * pulse), 3.0)

	for f: CityDistrictDef in _features:
		match f.feature:
			&"line":
				if f.line.size() >= 2:
					HoloMapStyle.glow_line(self, _project(f.line[0]), _project(f.line[1]), _c_cyan, 3.0, 8.0)
			&"ring":
				HoloMapStyle.dashed_circle(self, _project(f.center), f.radius * _city_scale, HoloMapStyle.alpha(_c_cyan, 0.65 * flicker), 2.0, 12.0, 10.0, 64)
			&"contours":
				for r: float in f.radii:
					draw_arc(_project(f.center), r * _city_scale, 0.0, TAU, 48, HoloMapStyle.alpha(_c_cyan, 0.45), 2.0)

	HoloMapLabels.draw_all(self, HoloMapLabels.resolve(labels, Rect2(Vector2.ZERO, size)), font)

	for pin: Dictionary in HoloMapCityView.unique_pins(_area_pins, _current_area_id()):
		var p: CityDistrictDef = pin["def"]
		HoloMapMarkers.draw_area_pin(self, _project(p.center), bool(pin["active"]), pulse, _c_cyan)


func city_label_set(font: Font) -> Array[HoloMapLabel]:
	_ensure_city_fit()
	return HoloMapCityView.labels(font, _districts, _area_pins, _city_scale, _city_offset, _current_area_id(), _c_cyan)


func area_label_set(font: Font) -> Array[HoloMapLabel]:
	return HoloMapAreaView.label_set(font, _plan, _fit, _style.colour(&"c_muted"))


func _ensure_city_fit() -> void:
	var bounds: Rect2 = HoloMapGeo.city_bounds(_districts, _features, _area_pins, Rect2(Vector2.ZERO, size))
	var tr: Dictionary = HoloMapGeo.fit(bounds, size, _CITY_MARGIN)
	_city_scale = float(tr.get("scale", 0.0))
	_city_offset = tr.get("offset", Vector2.ZERO) as Vector2


func _flicker() -> Dictionary:
	for f: CityDistrictDef in _features:
		if f.feature == &"flicker":
			return {"period": f.flicker_period, "base": f.flicker_base, "amplitude": f.flicker_amplitude}
	return {"period": 1.6, "base": 0.85, "amplitude": 0.15}


func _current_area_id() -> StringName:
	return area_def.id if area_def != null else &""


func _project(geo: Vector2) -> Vector2:
	return HoloMapGeo.project(geo, _city_scale, _city_offset)
