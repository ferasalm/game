class_name YawTurn
extends RefCounted
## Pure turning for a model: the yaw (radians, about +y; 0 faces +z) of a ground direction and a capped step toward
## it that always takes the short way round. No nodes here.


## The yaw that faces `dir` (x, z on the ground); `fallback` when it has no length.
static func yaw_of(dir: Vector3, fallback: float) -> float:
	if Vector2(dir.x, dir.z).length_squared() < 0.0001:
		return fallback
	return atan2(dir.x, dir.z)


## One step from `current` toward `target`, at most `max_rate` rad/s over `delta` seconds, the short way round.
static func step(current: float, target: float, max_rate: float, delta: float) -> float:
	var gap: float = wrapf(target - current, -PI, PI)
	var most: float = max_rate * delta
	return current + clampf(gap, -most, most)


## True when `current` is within `tolerance` radians of `target` (the short way round).
static func arrived(current: float, target: float, tolerance: float = 0.01) -> bool:
	return absf(wrapf(target - current, -PI, PI)) <= tolerance
