class_name PatrolSafety
extends RefCounted
## Where the party may stand with respect to the patrols: distance to a patrol lane (a segment, flat on the floor),
## the spot to stand on after a battle (the old one if it is clear, else the nearest clear cell) and the spot
## "Unstuck" picks (the newest remembered spot that is clear and not where the player is wedged, else the nearest
## safe place). Pure: lanes are PackedVector3Array([a, b]) and cells are plain points.


## Flat distance from p to the segment of a lane.
static func lane_distance(p: Vector3, lane: PackedVector3Array) -> float:
	var a := Vector2(lane[0].x, lane[0].z)
	var b := Vector2(lane[lane.size() - 1].x, lane[lane.size() - 1].z)
	var closest: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), a, b)
	return Vector2(p.x, p.z).distance_to(closest)


static func nearest_lane_distance(p: Vector3, lanes: Array[PackedVector3Array]) -> float:
	var best: float = INF
	for lane: PackedVector3Array in lanes:
		best = minf(best, lane_distance(p, lane))
	return best


static func is_clear(p: Vector3, lanes: Array[PackedVector3Array], min_distance: float) -> bool:
	return nearest_lane_distance(p, lanes) >= min_distance


## The spot to stand on after a battle: `origin` when it is clear of every lane, else the clear candidate nearest to
## it, else (nothing is clear) the candidate farthest from the lanes.
static func return_spot(origin: Vector3, candidates: Array[Vector3], lanes: Array[PackedVector3Array],
		min_distance: float) -> Vector3:
	if is_clear(origin, lanes, min_distance):
		return origin
	var best: Vector3 = origin
	var best_gap: float = INF
	var farthest: Vector3 = origin
	var farthest_clearance: float = -1.0
	for c: Vector3 in candidates:
		var clearance: float = nearest_lane_distance(c, lanes)
		if clearance > farthest_clearance:
			farthest_clearance = clearance
			farthest = c
		var gap: float = Vector2(c.x - origin.x, c.z - origin.z).length()
		if clearance >= min_distance and gap < best_gap:
			best_gap = gap
			best = c
	return best if best_gap < INF else farthest


## The spot "Unstuck" uses. spots: remembered standing spots, oldest first. A spot counts when it is at least
## min_move from `current` (the player may be wedged right there) and min_distance from every lane. If none does,
## the nearest of `safe_places` that is clear of the lanes (else the nearest of them) is used; with no safe place
## at all the newest remembered spot, else current.
static func unstuck_spot(current: Vector3, spots: Array[Vector3], safe_places: Array[Vector3],
		lanes: Array[PackedVector3Array], min_distance: float, min_move: float) -> Vector3:
	for i: int in range(spots.size() - 1, -1, -1):
		if _flat(spots[i], current) >= min_move and is_clear(spots[i], lanes, min_distance):
			return spots[i]
	var nearest: Vector3 = current
	var nearest_gap: float = INF
	var nearest_clear: Vector3 = current
	var nearest_clear_gap: float = INF
	for place: Vector3 in safe_places:
		var gap: float = _flat(place, current)
		if gap < nearest_gap:
			nearest_gap = gap
			nearest = place
		if gap < nearest_clear_gap and is_clear(place, lanes, min_distance):
			nearest_clear_gap = gap
			nearest_clear = place
	if nearest_clear_gap < INF:
		return nearest_clear
	if nearest_gap < INF:
		return nearest
	return spots[spots.size() - 1] if not spots.is_empty() else current


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
