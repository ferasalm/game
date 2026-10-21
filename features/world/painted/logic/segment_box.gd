class_name SegmentBox
extends RefCounted
## Pure helpers of the camera cut-away: does the line from the camera to the party cross a box (slab test), which
## world boxes could ever block it (instance transforms of a mesh, tall enough), how a point weighs in the tube
## around the line (the same maths as occlusion_dither.gdshaderinc), and the ease of the fade amount.


const FLOOR_SOFT: float = 0.4  ## metres over which the cut fades in above min_y


## True when the segment from..to passes through box grown by pad on every side.
static func hits(from: Vector3, to: Vector3, box: AABB, pad: float = 0.0) -> bool:
	var lo: Vector3 = box.position - Vector3.ONE * pad
	var hi: Vector3 = box.end + Vector3.ONE * pad
	var dir: Vector3 = to - from
	var t_min: float = 0.0
	var t_max: float = 1.0
	for axis: int in 3:
		if absf(dir[axis]) < 0.000001:
			if from[axis] < lo[axis] or from[axis] > hi[axis]:
				return false
			continue
		var t1: float = (lo[axis] - from[axis]) / dir[axis]
		var t2: float = (hi[axis] - from[axis]) / dir[axis]
		t_min = maxf(t_min, minf(t1, t2))
		t_max = minf(t_max, maxf(t1, t2))
		if t_min > t_max:
			return false
	return true


## True when any of the boxes is crossed by the segment.
static func any_hit(from: Vector3, to: Vector3, boxes: Array[AABB], pad: float = 0.0) -> bool:
	for box: AABB in boxes:
		if hits(from, to, box, pad):
			return true
	return false


## World boxes of the mesh instances that stand at least min_height above floor_y (the lower ones can never stand
## between a high camera and the party, so they are not tested every frame; a box longer than max_size is a merged
## mesh, not one block, and is left out).
static func boxes_of(local_box: AABB, transforms: Array[Transform3D], floor_y: float, min_height: float,
		max_size: float = 100000.0) -> Array[AABB]:
	var out: Array[AABB] = []
	for xf: Transform3D in transforms:
		var box: AABB = xf * local_box
		if box.end.y - floor_y >= min_height and box.size.length() <= max_size:
			out.append(box)
	return out


## How much the cut-away takes of a point: 1 inside the tube (radius, with a soft edge outside it) around the line
## from camera to focus, 0 outside it, in the last margin metres before the focus and below min_y (the floor stays).
static func tube_weight(point: Vector3, camera: Vector3, focus: Vector3, radius: float, soft: float, margin: float,
		min_y: float = -1000.0) -> float:
	var line: Vector3 = focus - camera
	var length: float = line.length()
	if length < 0.001:
		return 0.0
	var along: float = (point - camera).dot(line) / length
	var closest: Vector3 = camera + line / length * clampf(along, 0.0, length)
	var across: float = point.distance_to(closest)
	var inside: float = 1.0 - smoothstep(radius, radius + soft, across)
	var before: float = 1.0 - smoothstep(length - margin - 1.0, length - margin, along)
	return inside * before * smoothstep(min_y, min_y + FLOOR_SOFT, point.y)


## Moves current toward target by at most speed * delta.
static func eased(current: float, target: float, speed: float, delta: float) -> float:
	return move_toward(current, target, speed * delta)
