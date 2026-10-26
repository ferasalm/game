class_name IsoWalk
extends RefCounted
## Pure walking rules of an iso room (docs/design/first-playable.md section 2): whether a feet point may stand (inside
## the walkable outline, outside every hole), a step that slides along the edge it hits instead of stopping, and the
## screen-space velocity of an input (y foreshortened, so "up" crosses the floor as fast as it looks).

const Y_SQUASH: float = 0.55  ## screen y speed share of the x speed on a 2:1 plate
const SLIDE_TRIES: int = 2


static func can_stand(point: Vector2, outline: PackedVector2Array, holes: Array[PackedVector2Array]) -> bool:
	if not Geometry2D.is_point_in_polygon(point, outline):
		return false
	for hole: PackedVector2Array in holes:
		if Geometry2D.is_point_in_polygon(point, hole):
			return false
	return true


## Where the feet end after trying to move by `delta`: the full step if it is free, else the step's part along the
## x or y axis that is free (sliding along a wall), else no move.
static func step(from: Vector2, delta: Vector2, outline: PackedVector2Array, holes: Array[PackedVector2Array]) -> Vector2:
	if delta == Vector2.ZERO:
		return from
	if can_stand(from + delta, outline, holes):
		return from + delta
	var along_x := Vector2(delta.x, delta.y * 0.25)
	var along_y := Vector2(delta.x * 0.25, delta.y)
	for candidate: Vector2 in [along_x, along_y, Vector2(delta.x, 0.0), Vector2(0.0, delta.y)]:
		if can_stand(from + candidate, outline, holes):
			return from + candidate
	return from


## Screen velocity for a stick or key direction (any length; clamped to 1) at `speed` pixels per second.
static func velocity(input: Vector2, speed: float) -> Vector2:
	var dir: Vector2 = input.limit_length(1.0)
	return Vector2(dir.x, dir.y * Y_SQUASH) * speed


## The walkable point nearest to `point` among a few tries toward `toward` (for spawning fighters on the map).
static func nearest_free(point: Vector2, toward: Vector2, outline: PackedVector2Array,
		holes: Array[PackedVector2Array]) -> Vector2:
	for i: int in 11:
		var p: Vector2 = point.lerp(toward, float(i) / 10.0)
		if can_stand(p, outline, holes):
			return p
	return toward
