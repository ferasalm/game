class_name PoseMatch
extends RefCounted
## Pure maths of pose retargeting between two humanoid rigs with the same bone names but other bone axes and rest
## poses (a Rodin body driven by the Quaternius library): a constant per-bone offset so the target bone always points
## where the source bone points, and the hips' travel scaled from one leg length to the other.


## The shortest rotation that turns direction `from` into direction `to` (identity for a zero vector).
static func swing(from: Vector3, to: Vector3) -> Basis:
	if from.is_zero_approx() or to.is_zero_approx():
		return Basis.IDENTITY
	var a: Vector3 = from.normalized()
	var b: Vector3 = to.normalized()
	var axis: Vector3 = a.cross(b)
	var dot: float = clampf(a.dot(b), -1.0, 1.0)
	if axis.is_zero_approx():
		if dot > 0.0:
			return Basis.IDENTITY
		var side: Vector3 = Vector3.UP if absf(a.y) < 0.9 else Vector3.RIGHT
		return Basis(a.cross(side).normalized(), PI)
	return Basis(axis.normalized(), acos(dot))


## The constant offset K of one bone (model-space rest rotations `source_rest`, `target_rest`; rest directions to the
## bone's child `source_dir`, `target_dir`): target_pose = source_pose * K keeps the target bone on the source's
## direction, and at the source's rest pose the target bone points along `source_dir`.
static func offset(source_rest: Basis, target_rest: Basis, source_dir: Vector3, target_dir: Vector3) -> Basis:
	var align: Basis = swing(source_dir, target_dir)
	return source_rest.orthonormalized().inverse() * align.inverse() * target_rest.orthonormalized()


## Where the target's hips go: its rest position plus the source's travel from rest, scaled by hip height.
static func hips(target_rest: Vector3, source_rest: Vector3, source_now: Vector3) -> Vector3:
	var ratio: float = target_rest.y / source_rest.y if absf(source_rest.y) > 0.001 else 1.0
	return target_rest + (source_now - source_rest) * ratio


## The bone on the other side: `hand_l` <-> `hand_r`; a centre bone (`spine_02`) is its own.
static func mirror_name(bone: String) -> String:
	if bone.ends_with("_l"):
		return bone.left(-2) + "_r"
	if bone.ends_with("_r"):
		return bone.left(-2) + "_l"
	return bone


## A model-space transform reflected left-right (x -> -x): a proper rotation again, with the position mirrored.
static func reflect(xf: Transform3D) -> Transform3D:
	var flip := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
	return Transform3D(flip * xf.basis * flip, flip * xf.origin)
