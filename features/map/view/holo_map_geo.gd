class_name HoloMapGeo
extends RefCounted
## purpose: Project city map features from world metres to screen space and compute the fitting bounds.


static func city_bounds(districts: Array[CityDistrictDef], features: Array[CityDistrictDef], pins: Array[CityDistrictDef], fallback: Rect2) -> Rect2:
	var min_pt := Vector2(INF, INF)
	var max_pt := Vector2(-INF, -INF)
	for d: CityDistrictDef in districts:
		for p: Vector2 in d.polygon:
			min_pt = min_pt.min(p)
			max_pt = max_pt.max(p)
	for f: CityDistrictDef in features:
		for p: Vector2 in f.line:
			min_pt = min_pt.min(p)
			max_pt = max_pt.max(p)
		if f.radius > 0.0:
			min_pt = min_pt.min(f.center - Vector2(f.radius, f.radius))
			max_pt = max_pt.max(f.center + Vector2(f.radius, f.radius))
		for r: float in f.radii:
			min_pt = min_pt.min(f.center - Vector2(r, r))
			max_pt = max_pt.max(f.center + Vector2(r, r))
		min_pt = min_pt.min(f.center)
		max_pt = max_pt.max(f.center)
	for p: CityDistrictDef in pins:
		min_pt = min_pt.min(p.center)
		max_pt = max_pt.max(p.center)
	if min_pt.x == INF:
		return fallback
	return Rect2(min_pt, max_pt - min_pt)


static func project(geo: Vector2, scale: float, offset: Vector2) -> Vector2:
	return offset + Vector2(geo.x, -geo.y) * scale


static func to_screen_polygon(poly: PackedVector2Array, scale: float, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	for i: int in range(poly.size()):
		out[i] = project(poly[i], scale, offset)
	return out


static func centroid(pts: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p: Vector2 in pts:
		c += p
	return c / float(max(pts.size(), 1))


static func fit(bounds: Rect2, target_size: Vector2, pad: float) -> Dictionary:
	var avail: Vector2 = target_size - Vector2(pad * 2.0, pad * 2.0)
	var scale: float = minf(avail.x / maxf(bounds.size.x, 1.0), avail.y / maxf(bounds.size.y, 1.0))
	var fitted: Vector2 = bounds.size * scale
	var offset: Vector2 = (target_size - fitted) * 0.5 - bounds.position * scale
	return {"scale": scale, "offset": offset}
