class_name AreaProblems
extends RefCounted
## Checks an AreaDef for layout problems: row widths, unmapped tiles, missing markers, out-of-bounds places.


static func check(area: AreaDef) -> PackedStringArray:
	var out := PackedStringArray()
	if area.rows.is_empty():
		out.append("no rows")
	for z: int in area.rows.size():
		if area.rows[z].length() != area.width():
			out.append("row %d is %d wide, row 0 is %d" % [z, area.rows[z].length(), area.width()])
		for ch: String in area.rows[z]:
			if not area.legend.has(ch):
				out.append("row %d: '%s' is not in the legend" % [z, ch])
	if area.vista.has_area() and not Rect2i(0, 0, area.width(), area.depth()).encloses(area.vista):
		out.append("the vista zone sticks out of the area")
	for marker: String in AreaDef.MARKERS:
		var count: int = "".join(area.rows).count(marker)
		if count != 1:
			out.append("marker %s appears %d times (must be once)" % [marker, count])
	out.append_array(_place_problems(area))
	return out


static func _place_problems(area: AreaDef) -> PackedStringArray:
	var out := PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	var bounds := Rect2(0.0, 0.0, area.width(), area.depth())
	for p: PlaceDef in area.places:
		if seen.has(p.id):
			out.append("place %s appears twice" % p.id)
		seen[p.id] = true
		var points: Array[Vector3] = []
		if p.kind != PlaceDef.VISTA and p.kind != PlaceDef.CAMERA_ZONE:
			points.append(p.pos)
		if p.kind == PlaceDef.PATROL:
			points.append(p.end)
		for point: Vector3 in points:
			if not bounds.has_point(Vector2(point.x, point.z)):
				out.append("place %s is outside the area" % p.id)
	return out
