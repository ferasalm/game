class_name CityDistrictDef
extends Def
## purpose: Defines a city map feature: district polygon, road line, ring/contours or area pin.

var name_key: String = ""
var feature: StringName = &"district"
var polygon: PackedVector2Array = PackedVector2Array()
var is_old_city: bool = false
## Line features (al-Saila, Zubairi): two or more world points.
var line: PackedVector2Array = PackedVector2Array()
## Ring/contour geometry in world units.
var center: Vector2 = Vector2.ZERO
var radius: float = 0.0
var radii: PackedFloat32Array = PackedFloat32Array()
## Area pin: which area id this pin represents.
var area_id: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	feature = StringName(r.text("feature", "district", false))
	is_old_city = r.flag("is_old_city", false)
	var raw_data: Dictionary = r.get("_data") as Dictionary
	polygon = _read_points(raw_data, "polygon")
	line = _read_points(raw_data, "points")
	center = _read_point(raw_data, "center")
	radius = r.number("radius", 0.0, 20000.0, 0.0, false)
	radii = _read_floats(raw_data, "radii")
	area_id = StringName(r.text("area_id", "", false))
	if feature == &"district" and polygon.size() < 3:
		r.problem("polygon", "needs at least 3 points")


func _read_points(data: Dictionary, key: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	if not data.has(key) or not data[key] is Array:
		return out
	for item: Variant in (data[key] as Array):
		var pt: Vector2 = _to_point(item)
		if pt != Vector2(-INF, -INF):
			out.append(pt)
	return out


func _read_point(data: Dictionary, key: String) -> Vector2:
	if not data.has(key):
		return Vector2.ZERO
	return _to_point(data[key])


func _to_point(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return Vector2(-INF, -INF)


func _read_floats(data: Dictionary, key: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if not data.has(key) or not data[key] is Array:
		return out
	for item: Variant in (data[key] as Array):
		if item is float or item is int:
			out.append(float(item))
	return out


func references() -> Array[Array]:
	return []
