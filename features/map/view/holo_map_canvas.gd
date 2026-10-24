class_name HoloMapCanvas
extends Control
## purpose: 1200x800 holographic map canvas: rooftop floor plan or full city map with neon glow and HUD dressing.

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
var _neon_layer: Control
var _overlay_layer: Control
var _city_scale: float = 0.0
var _city_offset: Vector2 = Vector2.ZERO
var _radial: Dictionary = {}


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
	_setup_layers()
	_load_city_data()


func _setup_layers() -> void:
	_neon_layer = Control.new()
	_neon_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_neon_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_neon_layer.material = add_mat
	_neon_layer.draw.connect(_on_neon_draw)
	add_child(_neon_layer)

	_overlay_layer = Control.new()
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.draw.connect(_on_overlay_draw)
	add_child(_overlay_layer)

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
			&"district": _districts.append(d)
			&"area_pin": _area_pins.append(d)
			_: _features.append(d)


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
	if mode == Mode.AREA:
		_neon_layer.visible = false
		_overlay_layer.visible = false
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, _style.colour(&"c_glass_menu"), true)
		draw_rect(rect, HoloMapStyle.alpha(_c_cyan, 0.4), false, 2.0)
		_draw_area_plan()
	else:
		_neon_layer.visible = true
		_overlay_layer.visible = true
		_neon_layer.queue_redraw()
		_overlay_layer.queue_redraw()
		var look := HoloCityLook.load_from_content()
		HoloCityHud.draw_background_and_grid(self, size, look)


func _on_neon_draw() -> void:
	if mode != Mode.CITY:
		return
	var look := HoloCityLook.load_from_content()
	var flick: Dictionary = _flicker()
	var pulse: float = sin(pulse_time * TAU / maxf(float(flick["period"]), 0.1)) * 0.5 + 0.5
	var pin_active: bool = _is_current_area_active()
	HoloCityOldTown.draw(_neon_layer, look, pulse, pin_active)
	HoloCityDistricts.draw(_neon_layer, look)


func _on_overlay_draw() -> void:
	if mode != Mode.CITY:
		return
	var font: Font = Ui.theme().default_font
	var look := HoloCityLook.load_from_content()
	var labels: Array[HoloMapLabel] = city_label_set(font)
	var pin_screen := Vector2(781.0, 392.0)
	var pin_rect := Rect2(pin_screen - Vector2(16.0, 16.0), Vector2(32.0, 32.0))
	var obstacles: Array[Rect2] = [pin_rect]
	var resolved: Array[HoloMapLabel] = HoloMapLabels.resolve(labels, Rect2(Vector2.ZERO, size), obstacles)
	HoloMapLabels.draw_all(_overlay_layer, resolved, font)
	HoloCityHud.draw_overlay(_overlay_layer, size, look, font)


func _draw_area_plan() -> void:
	if _plan.is_empty() or not _fit.has("scale"):
		return
	var colors := {
		&"default": _c_cyan, &"npc": _c_good, &"vendor": _c_brass, &"quest": _c_amber,
		&"muted": _style.colour(&"c_muted"),
	}
	HoloMapAreaView.draw(self, _plan, _fit, _markers, player_world_pos, colors, Ui.theme().default_font)


func city_label_set(font: Font) -> Array[HoloMapLabel]:
	_ensure_city_fit()
	return HoloMapCityView.labels(font, _districts, _area_pins, _city_scale, _city_offset, _current_area_id(), _c_cyan,
		_radial["center"], float(_radial["k"]), float(_radial["r"]))


func area_label_set(font: Font) -> Array[HoloMapLabel]:
	return HoloMapAreaView.label_set(font, _plan, _fit, _style.colour(&"c_muted"))


func _ensure_city_fit() -> void:
	_radial = HoloMapGeo.radial_params(_features, _area_pins, _current_area_id())
	var center: Vector2 = _radial["center"]
	var k: float = float(_radial["k"])
	var r: float = float(_radial["r"])
	var bounds: Rect2 = HoloMapGeo.city_bounds(_districts, _features, _area_pins, Rect2(Vector2.ZERO, size), center, k, r)
	var tr: Dictionary = HoloMapGeo.fit(bounds, size, _CITY_MARGIN)
	_city_scale = float(tr.get("scale", 0.0))
	_city_offset = tr.get("offset", Vector2.ZERO) as Vector2


func _flicker() -> Dictionary:
	for f: CityDistrictDef in _features:
		if f.feature == &"flicker":
			return {"period": f.flicker_period, "base": f.flicker_base, "amplitude": f.flicker_amplitude}
	return {"period": 1.6, "base": 0.85, "amplitude": 0.15}


func _is_current_area_active() -> bool:
	var cur: StringName = _current_area_id()
	for p: CityDistrictDef in _area_pins:
		if p.area_id == cur:
			return true
	return false


func _current_area_id() -> StringName:
	return area_def.id if area_def != null else &""


func _project(geo: Vector2) -> Vector2:
	return HoloMapGeo.project(geo, _city_scale, _city_offset, _radial.get("center", Vector2.ZERO),
		float(_radial.get("k", 0.0)), float(_radial.get("r", HoloMapGeo.DEFAULT_RADIAL_R)))
