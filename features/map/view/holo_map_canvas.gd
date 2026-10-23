class_name HoloMapCanvas
extends Control
## purpose: 1200x800 holographic map canvas drawing area floor plan or full city map with scanlines.

enum Mode { AREA, CITY }

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
var _scanlines: ColorRect


func _init() -> void:
	position = Vector2(360.0, 140.0)
	custom_minimum_size = Vector2(1200.0, 800.0)
	size = Vector2(1200.0, 800.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = Ui.style()
	_c_cyan = _style.colour(&"c_cyan")
	_c_good = _style.colour(&"c_good")
	_c_brass = _style.colour(&"c_brass")
	_c_amber = _style.colour(&"c_qam_amber")
	_setup_scanlines()
	_load_city_districts()


func _setup_scanlines() -> void:
	_scanlines = ColorRect.new()
	_scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://features/map/view/holo_scan.gdshader")
	_scanlines.material = mat
	add_child(_scanlines)


func _load_city_districts() -> void:
	_districts.clear()
	for d_id: StringName in ContentDB.ids("city_district"):
		var def := ContentDB.get_def("city_district", d_id) as CityDistrictDef
		if def != null:
			_districts.append(def)


func refresh_plan() -> void:
	if area_def == null:
		return
	_plan = MapPlan.plan(area_def)
	_fit = MapPlan.fit(_plan, Rect2(Vector2.ZERO, size))
	var marker_defs: Array = []
	for m_id: StringName in ContentDB.ids("map_marker"):
		marker_defs.append(ContentDB.get_def("map_marker", m_id))
	_markers = MapPlan.markers(area_def, marker_defs, flags)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, _style.colour(&"c_glass_menu"), true)
	draw_rect(rect, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.4), false, 2.0)
	if mode == Mode.AREA:
		_draw_area_plan()
	else:
		_draw_city_map()


func _draw_area_plan() -> void:
	if _plan.is_empty() or not _fit.has("scale"):
		return
	var scale_val: float = float(_fit["scale"])
	var offset: Vector2 = _fit["offset"]
	var font: Font = Ui.theme().default_font

	for run: Rect2i in _plan.get("runs", []):
		var r := Rect2(Vector2(run.position) * scale_val + offset, Vector2(run.size) * scale_val)
		draw_rect(r, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.08), true)
		draw_rect(r, _c_cyan, false, 2.0)

	for seg: PackedVector2Array in _plan.get("crossings", []):
		if seg.size() >= 2:
			draw_dashed_line(seg[0] * scale_val + offset, seg[1] * scale_val + offset, _c_cyan, 2.0, 6.0)

	for pl: Dictionary in _plan.get("places", []):
		var name_key: String = pl.get("name_key", "")
		if not name_key.is_empty():
			var pos: Vector2 = pl.get("pos", Vector2.ZERO) * scale_val + offset
			var label_text: String = Ui.text(name_key)
			draw_string(font, pos + Vector2(-60.0, -18.0), label_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 16, _style.colour(&"c_muted"))

	for m: Dictionary in _markers:
		var pos: Vector2 = m.get("pos", Vector2.ZERO) * scale_val + offset
		_draw_marker_icon(pos, StringName(m.get("kind", "")))

	var p_screen: Vector2 = Vector2(player_world_pos.x, player_world_pos.z) * scale_val + offset
	_draw_marker_icon(p_screen, &"player")


func _draw_city_map() -> void:
	var font: Font = Ui.theme().default_font
	var center := size * 0.5
	var scale_f: float = minf(size.x, size.y) * 0.8 / 2000.0
	var pulse: float = sin(pulse_time * TAU / 1.6) * 0.5 + 0.5

	for d: CityDistrictDef in _districts:
		var pts := PackedVector2Array()
		var centroid := Vector2.ZERO
		for pt: Vector2 in d.polygon:
			var sp: Vector2 = center + pt * scale_f
			pts.append(sp)
			centroid += sp
		if pts.size() >= 3:
			centroid /= float(pts.size())
			var fill := Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.15 if d.is_old_city else 0.06)
			draw_colored_polygon(pts, fill)
			draw_polyline(pts, _c_cyan, 2.0)
			draw_line(pts[-1], pts[0], _c_cyan, 2.0)
			var d_name: String = Ui.text(d.name_key)
			draw_string(font, centroid + Vector2(-60.0, 6.0), d_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 16, _c_cyan)
		if d.is_old_city:
			var ring_r: float = 30.0 + pulse * 10.0
			draw_arc(centroid, ring_r, 0.0, TAU, 36, Color(_c_cyan.r, _c_cyan.g, _c_cyan.b, 0.6 + 0.4 * pulse), 3.0)


func _draw_marker_icon(pos: Vector2, kind: StringName) -> void:
	var col := _c_cyan
	if kind == &"npc":
		col = _c_good
	elif kind == &"vendor":
		col = _c_brass
	elif kind == &"quest":
		col = _c_amber
	draw_circle(pos, 22.0, Color(col.r, col.g, col.b, 0.22))
	if kind == &"player":
		var pts := PackedVector2Array([
			Vector2(pos.x, pos.y - 18.0), Vector2(pos.x + 18.0, pos.y),
			Vector2(pos.x, pos.y + 18.0), Vector2(pos.x - 18.0, pos.y)
		])
		draw_colored_polygon(pts, _c_cyan)
		draw_polyline(pts, Color.WHITE, 1.5)
	elif kind == &"npc":
		draw_arc(pos, 16.0, 0.0, TAU, 32, _c_good, 3.0)
	elif kind == &"vendor":
		var cart := PackedVector2Array([
			Vector2(pos.x - 12.0, pos.y - 9.0), Vector2(pos.x + 12.0, pos.y - 9.0),
			Vector2(pos.x + 8.0, pos.y + 6.0), Vector2(pos.x - 8.0, pos.y + 6.0)
		])
		draw_colored_polygon(cart, _c_brass)
		draw_circle(Vector2(pos.x - 6.0, pos.y + 11.0), 3.0, _c_brass)
		draw_circle(Vector2(pos.x + 6.0, pos.y + 11.0), 3.0, _c_brass)
	elif kind == &"quest":
		draw_line(Vector2(pos.x, pos.y - 14.0), Vector2(pos.x, pos.y + 3.0), _c_amber, 4.0)
		draw_circle(Vector2(pos.x, pos.y + 12.0), 3.0, _c_amber)
