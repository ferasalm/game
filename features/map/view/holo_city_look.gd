class_name HoloCityLook
extends RefCounted
## purpose: Reads, validates and applies holographic city map styling from content JSON.

var _colors: Dictionary = {}
var _alphas: Dictionary = {}
var _widths: Dictionary = {}
var _sizes: Dictionary = {}
var _counts: Dictionary = {}
var _seeds: Dictionary = {}


static func load_from_content() -> HoloCityLook:
	var look := HoloCityLook.new()
	var def := ContentDB.get_def("city_district", &"look") as CityDistrictDef
	if def == null:
		push_error("HoloCityLook: missing look definition in city_district")
		return look
	look._init_from_data(def.look_data)
	return look


func _init_from_data(data: Dictionary) -> void:
	_colors = data.get("colors", {}) as Dictionary
	_alphas = data.get("alphas", {}) as Dictionary
	_widths = data.get("widths", {}) as Dictionary
	_sizes = data.get("sizes", {}) as Dictionary
	_counts = data.get("counts", {}) as Dictionary
	_seeds = data.get("seeds", {}) as Dictionary


func has_key(section: String, key: String) -> bool:
	var sec: Dictionary = _section_dict(section)
	return sec.has(key)


func require_key(section: String, key: String, on_fail: Callable = Callable()) -> Variant:
	var sec: Dictionary = _section_dict(section)
	if not sec.has(key):
		if on_fail.is_valid():
			on_fail.call()
		else:
			push_error("HoloCityLook: missing key '%s' in section '%s'" % [key, section])
		return null
	return sec[key]


func get_color(key: String) -> Color:
	var val: Variant = require_key("colors", key)
	if val == null:
		return Color.MAGENTA
	return Color(str(val))


func get_alpha(key: String) -> float:
	var val: Variant = require_key("alphas", key)
	return float(val) if val != null else 1.0


func get_width(key: String) -> float:
	var val: Variant = require_key("widths", key)
	return float(val) if val != null else 1.0


func get_size(key: String) -> float:
	var val: Variant = require_key("sizes", key)
	return float(val) if val != null else 0.0


func get_count(key: String) -> int:
	var val: Variant = require_key("counts", key)
	return int(val) if val != null else 0


func get_seed(key: String) -> int:
	var val: Variant = require_key("seeds", key)
	return int(val) if val != null else 0


func color_alpha(color_key: String, alpha_key: String) -> Color:
	var c: Color = get_color(color_key)
	return Color(c.r, c.g, c.b, get_alpha(alpha_key))


func draw_neon_line(canvas: CanvasItem, from: Vector2, to: Vector2, col: Color) -> void:
	canvas.draw_line(from, to, Color(col.r, col.g, col.b, get_alpha("neon_wide")), get_width("neon_wide"))
	canvas.draw_line(from, to, Color(col.r, col.g, col.b, get_alpha("neon_mid")), get_width("neon_mid"))
	canvas.draw_line(from, to, Color(col.r, col.g, col.b, get_alpha("neon_core")), get_width("neon_core"))


func draw_neon_polyline(canvas: CanvasItem, pts: PackedVector2Array, col: Color, closed: bool = false) -> void:
	if pts.size() < 2:
		return
	var line_pts := pts
	if closed:
		line_pts = PackedVector2Array(pts)
		line_pts.append(pts[0])
	canvas.draw_polyline(line_pts, Color(col.r, col.g, col.b, get_alpha("neon_wide")), get_width("neon_wide"))
	canvas.draw_polyline(line_pts, Color(col.r, col.g, col.b, get_alpha("neon_mid")), get_width("neon_mid"))
	canvas.draw_polyline(line_pts, Color(col.r, col.g, col.b, get_alpha("neon_core")), get_width("neon_core"))


func draw_neon_circle(canvas: CanvasItem, center: Vector2, radius: float, col: Color, segments: int = 48) -> void:
	draw_neon_arc(canvas, center, radius, 0.0, TAU, segments, col)


func draw_neon_arc(canvas: CanvasItem, center: Vector2, radius: float, start_a: float, end_a: float,
		segments: int, col: Color) -> void:
	canvas.draw_arc(center, radius, start_a, end_a, segments,
		Color(col.r, col.g, col.b, get_alpha("neon_wide")), get_width("neon_wide"))
	canvas.draw_arc(center, radius, start_a, end_a, segments,
		Color(col.r, col.g, col.b, get_alpha("neon_mid")), get_width("neon_mid"))
	canvas.draw_arc(center, radius, start_a, end_a, segments,
		Color(col.r, col.g, col.b, get_alpha("neon_core")), get_width("neon_core"))


func _section_dict(section: String) -> Dictionary:
	match section:
		"colors": return _colors
		"alphas": return _alphas
		"widths": return _widths
		"sizes": return _sizes
		"counts": return _counts
		"seeds": return _seeds
		_: return {}
