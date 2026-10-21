class_name CameraLimits
extends RefCounted
## The exploration camera's frame rules: the camera target is the player clamped into the area's limits (x and z
## ranges from camera.json), so the camera never leaves the commons even when the player walks to the east roof.
## Also the camera point for a pitch and distance (the camera stands behind and above the target: x equal, z + d,
## y + look_height + h). Pure.


## p with x and z clamped to the ranges; a range of (0, 0) leaves that axis alone.
static func clamp_target(p: Vector3, range_x: Vector2, range_z: Vector2) -> Vector3:
	var out: Vector3 = p
	if range_x != Vector2.ZERO:
		out.x = clampf(p.x, range_x.x, range_x.y)
	if range_z != Vector2.ZERO:
		out.z = clampf(p.z, range_z.x, range_z.y)
	return out


## Where the camera stands for a target: d = distance * cos(pitch) behind (+z), h = distance * sin(pitch) above.
static func camera_point(target: Vector3, pitch_deg: float, distance: float, look_height: float) -> Vector3:
	var pitch: float = deg_to_rad(pitch_deg)
	return target + Vector3(0.0, look_height + sin(pitch) * distance, cos(pitch) * distance)


## True when the point is inside the box lo..hi grown by margin on every side.
static func inside_box(point: Vector3, lo: Vector3, hi: Vector3, margin: float) -> bool:
	return point.x > lo.x - margin and point.x < hi.x + margin and point.y > lo.y - margin \
		and point.y < hi.y + margin and point.z > lo.z - margin and point.z < hi.z + margin
