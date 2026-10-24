class_name ModelAnchors
extends RefCounted
## purpose: A live model's body anchors from its own height and width, with every share read from visual.json.


## Where a body spot is for a model, in metres from the visual's feet.
static func anchor(def: ModelDef, rig: ModelRig, facing: float, size: Vector2, to_root: Callable,
		rules: VisualRulesDef, which: StringName) -> Vector3:
	if def == null:
		return Vector3.ZERO
	match which:
		&"feet":
			return Vector3.ZERO
		&"head":
			return Vector3(0.0, size.y, 0.0)
	if rig != null and def.anchors.has(String(which)):
		var point: Vector3 = to_root.call(rig.bone_position(def.anchors[String(which)])) as Vector3
		if which == &"belt":
			point.z += size.x * rules.belt_depth
		return point
	return fallback(which, facing, size, rules)


## A body point for a rigid model (or a missing anchor), from its own height and width.
static func fallback(which: StringName, facing: float, size: Vector2, rules: VisualRulesDef) -> Vector3:
	var h: float = size.y if size.y > 0.0 else rules.fallback_height
	var w: float = size.x
	match which:
		&"chest":
			return Vector3(0.0, h * rules.chest_height, 0.0)
		&"belt":
			return Vector3(0.0, h * rules.belt_height, w * rules.belt_depth)
		&"hip":
			return Vector3(0.0, h * rules.belt_height, 0.0)
		&"arm", &"arm_left":
			return Vector3(facing * w * rules.arm_side, h * rules.arm_height, 0.0)
		&"hand", &"hand_left":
			return Vector3(facing * w * rules.hand_side, h * rules.hand_height, 0.0)
	return Vector3.ZERO
