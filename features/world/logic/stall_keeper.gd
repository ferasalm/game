class_name StallKeeper
extends RefCounted
## Where a stall keeper stands, pure: at the open end of his counter (the prop's -x end in its own frame), clear of
## its collide box by his body radius and a gap, so his body never pokes through the counter. Behind the counter the
## awning hides him from the play camera (playtest 2026-10-23), so he stands beside it and faces his customers.


## The floor point (x, z) at the end of a prop standing at `at`, turned by `yaw_deg` (0 = its front faces +z),
## whose collide box is `collide` (width, height, depth, centred on its base).
static func at_end(at: Vector2, yaw_deg: float, collide: Vector3, radius: float, gap: float) -> Vector2:
	var side := Vector2(-(collide.x / 2.0 + radius + gap), 0.0)
	return at + side.rotated(-deg_to_rad(yaw_deg))


## The yaw (degrees, 0 = +z) of someone at `from` looking at `to` on the floor.
static func facing(from: Vector2, to: Vector2) -> float:
	return rad_to_deg(atan2(to.x - from.x, to.y - from.y))
