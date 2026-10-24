class_name BodyAnchor
extends RefCounted
## purpose: The fallback body anchor points of a model with no rigged anchor bone (a rigid model, or a bone the
## def does not name): shares of the body's own height and width, as a distance from the feet.


const CHEST_HEIGHT: float = 0.72  ## chest, belt, arm and hand heights as shares of the body's height
const BELT_HEIGHT: float = 0.55
const ARM_HEIGHT: float = 0.62
const HAND_HEIGHT: float = 0.5
const DEFAULT_HEIGHT: float = 1.8  ## a def with no height falls back to a grown person's


static func point(which: StringName, height: float, width: float, facing: float) -> Vector3:
	var h: float = height if height > 0.0 else DEFAULT_HEIGHT
	match which:
		&"chest":
			return Vector3(0.0, h * CHEST_HEIGHT, 0.0)
		&"belt":
			return Vector3(0.0, h * BELT_HEIGHT, width * 0.4)
		&"hip":
			return Vector3(0.0, h * BELT_HEIGHT, 0.0)
		&"arm", &"arm_left":
			return Vector3(facing * width * 0.45, h * ARM_HEIGHT, 0.0)
		&"hand", &"hand_left":
			return Vector3(facing * width * 0.5, h * HAND_HEIGHT, 0.0)
	return Vector3.ZERO
