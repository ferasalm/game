class_name ModelAnchors
extends RefCounted
## purpose: Body points (feet, head, chest, belt, hip, arm, hand) from a model's height, width and rig.

const CHEST_HEIGHT: float = 0.72
const BELT_HEIGHT: float = 0.55
const ARM_HEIGHT: float = 0.62
const HAND_HEIGHT: float = 0.5


## The point for `which`; bone_point is called when the rig has that anchor (invalid = rigid fallback).
static func point(which: StringName, h: float, w: float, facing: float, bone_point: Callable) -> Vector3:
	if which == &"feet":
		return Vector3.ZERO
	if which == &"head":
		return Vector3(0.0, h, 0.0)
	if bone_point.is_valid():
		var found: Vector3 = bone_point.call()
		if which == &"belt":
			found.z += w * 0.4
		return found
	return _fallback(which, h if h > 0.0 else 1.8, w, facing)


static func _fallback(which: StringName, h: float, w: float, facing: float) -> Vector3:
	match which:
		&"chest":
			return Vector3(0.0, h * CHEST_HEIGHT, 0.0)
		&"belt":
			return Vector3(0.0, h * BELT_HEIGHT, w * 0.4)
		&"hip":
			return Vector3(0.0, h * BELT_HEIGHT, 0.0)
		&"arm", &"arm_left":
			return Vector3(facing * w * 0.45, h * ARM_HEIGHT, 0.0)
		&"hand", &"hand_left":
			return Vector3(facing * w * 0.5, h * HAND_HEIGHT, 0.0)
	return Vector3.ZERO
