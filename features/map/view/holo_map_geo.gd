class_name HoloMapGeo
extends RefCounted
## purpose: Project city map features from world metres to screen space with optional radial compression.

const DEFAULT_RADIAL_K: float = 1500.0
const DEFAULT_RADIAL_R: float = 9000.0


## Compresses world distance d from center: d' = R * d / (d + k). Directions stay true.
static func compress(point: Vector2, center: Vector2, k: float = DEFAULT_RADIAL_K, r: float = DEFAULT_RADIAL_R) -> Vector2:
	if k <= 0.0 or r <= 0.0:
		return point
	var v: Vector2 = point - center
	var d: float = v.length()
	if d == 0.0:
		return center
	var d_prime: float = r * d / (d + k)
	return center + (v / d) * d_prime


static func radial_params(features: Array[CityDistrictDef] = [], pins: Array[CityDistrictDef] = [], current_area_id: StringName = &"") -> Dictionary:
	var center := Vector2(110.0, -110.0)
	var k: float = DEFAULT_RADIAL_K
	var r: float = DEFAULT_RADIAL_R
	for p: CityDistrictDef in pins:
		if current_area_id != &"" and p.area_id == current_area_id:
			center = p.center
			if p.radial_k > 0.0:
				k = p.radial_k
			break
	for f: CityDistrictDef in features:
		if f.feature == &"radial":
			if f.center != Vector2.ZERO:
				center = f.center
			if f.radial_k > 0.0:
				k = f.radial_k
	return {"center": center, "k": k, "r": r}


static func city_bounds(districts: Array[CityDistrictDef], features: Array[CityDistrictDef], pins: Array[CityDistrictDef], fallback: Rect2, center: Vector2 = Vector2.ZERO, k: float = 0.0, r: float = DEFAULT_RADIAL_R) -> Rect2:
	var min_pt := Vector2(INF, INF)
	var max_pt := Vector2(-INF, -INF)
	for d: CityDistrictDef in districts:
		for p: Vector2 in d.polygon:
			var cp: Vector2 = compress(p, center, k, r) if k > 0.0 else p
			min_pt = min_pt.min(cp)
			max_pt = max_pt.max(cp)
	for f: CityDistrictDef in features:
		for p: Vector2 in f.line:
			var cp: Vector2 = compress(p, center, k, r) if k > 0.0 else p
			min_pt = min_pt.min(cp)
			max_pt = max_pt.max(cp)
		if f.radius > 0.0:
			var pts: Array[Vector2] = [f.center + Vector2(f.radius, 0.0), f.center - Vector2(f.radius, 0.0),
				f.center + Vector2(0.0, f.radius), f.center - Vector2(0.0, f.radius)]
			for cp_raw: Vector2 in pts:
				var cp: Vector2 = compress(cp_raw, center, k, r) if k > 0.0 else cp_raw
				min_pt = min_pt.min(cp)
				max_pt = max_pt.max(cp)
		for rad: float in f.radii:
			var pts: Array[Vector2] = [f.center + Vector2(rad, 0.0), f.center - Vector2(rad, 0.0),
				f.center + Vector2(0.0, rad), f.center - Vector2(0.0, rad)]
			for cp_raw: Vector2 in pts:
				var cp: Vector2 = compress(cp_raw, center, k, r) if k > 0.0 else cp_raw
				min_pt = min_pt.min(cp)
				max_pt = max_pt.max(cp)
		var fc: Vector2 = compress(f.center, center, k, r) if k > 0.0 else f.center
		min_pt = min_pt.min(fc)
		max_pt = max_pt.max(fc)
	for p: CityDistrictDef in pins:
		var pc: Vector2 = compress(p.center, center, k, r) if k > 0.0 else p.center
		min_pt = min_pt.min(pc)
		max_pt = max_pt.max(pc)
	if min_pt.x == INF:
		return fallback
	return Rect2(min_pt, max_pt - min_pt)


static func project(geo: Vector2, scale: float, offset: Vector2, center: Vector2 = Vector2.ZERO, k: float = 0.0, r: float = DEFAULT_RADIAL_R) -> Vector2:
	var p: Vector2 = compress(geo, center, k, r) if k > 0.0 else geo
	return offset + Vector2(p.x, -p.y) * scale


static func to_screen_polygon(poly: PackedVector2Array, scale: float, offset: Vector2, center: Vector2 = Vector2.ZERO, k: float = 0.0, r: float = DEFAULT_RADIAL_R) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	for i: int in range(poly.size()):
		out[i] = project(poly[i], scale, offset, center, k, r)
	return out


static func to_screen_polyline(line: PackedVector2Array, scale: float, offset: Vector2, center: Vector2 = Vector2.ZERO, k: float = 0.0, r: float = DEFAULT_RADIAL_R) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(line.size())
	for i: int in range(line.size()):
		out[i] = project(line[i], scale, offset, center, k, r)
	return out


static func centroid(pts: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p: Vector2 in pts:
		c += p
	return c / float(max(pts.size(), 1))


## Fits bounds into target_size with a uniform scale, centred and inset by margin_ratio on every side.
## The y axis is flipped by project(), so the top of the screen is bounds.end.y, not bounds.position.y.
static func fit(bounds: Rect2, target_size: Vector2, margin_ratio: float = 0.08) -> Dictionary:
	var inset: Vector2 = target_size * margin_ratio
	var avail: Vector2 = target_size - inset * 2.0
	var scale: float = minf(avail.x / maxf(bounds.size.x, 1.0), avail.y / maxf(bounds.size.y, 1.0))
	var fitted: Vector2 = bounds.size * scale
	var offset := Vector2(
		(target_size.x - fitted.x) * 0.5 - bounds.position.x * scale,
		(target_size.y - fitted.y) * 0.5 + bounds.end.y * scale)
	return {"scale": scale, "offset": offset}
