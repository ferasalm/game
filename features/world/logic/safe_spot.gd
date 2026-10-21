class_name SafeSpot
extends RefCounted
## Remembers where the player last stood still (the "unstuck" targets). A spot counts after idle_seconds without
## moving more than still_radius; a new spot closer than still_radius to the newest one only refreshes it. The two
## newest spots are kept, so standing wedged at the newest one still has an older place to go back to. Pure.

const KEPT: int = 2

var _idle_seconds: float
var _still_radius: float
var _spots: Array[Vector3] = []
var _anchor: Vector3
var _still_for: float = 0.0
var _fallback: Vector3


## fallback: the spot used before the player ever stood still (the spawn).
func _init(idle_seconds: float, still_radius: float, fallback: Vector3) -> void:
	_idle_seconds = idle_seconds
	_still_radius = still_radius
	_fallback = fallback
	_anchor = fallback


func update(position: Vector3, delta: float) -> void:
	if _flat_distance(position, _anchor) > _still_radius:
		_anchor = position
		_still_for = 0.0
		return
	_still_for += delta
	if _still_for >= _idle_seconds:
		_remember(_anchor)
		_still_for = 0.0


## The newest remembered spot that is not where the player is now (he may be wedged right there); the fallback when
## there is none.
func last_safe(current: Vector3) -> Vector3:
	for i: int in range(_spots.size() - 1, -1, -1):
		if _flat_distance(_spots[i], current) > _still_radius:
			return _spots[i]
	return _fallback


func spots() -> Array[Vector3]:
	return _spots.duplicate()


func _remember(spot: Vector3) -> void:
	if not _spots.is_empty() and _flat_distance(_spots[-1], spot) <= _still_radius:
		_spots[-1] = spot
		return
	_spots.append(spot)
	if _spots.size() > KEPT:
		_spots.remove_at(0)


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
