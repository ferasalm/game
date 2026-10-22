class_name PoseFollow
extends RefCounted
## Retargets at run time: a hidden source body with the library's rig plays the clips, and every frame each target bone
## of the same name takes the source bone's model-space rotation times a constant offset (PoseMatch), so a body with
## other bone axes and rest pose (Feras's Rodin models) moves like the library. Target bones the source lacks (twist,
## ik) keep their rest; the hips carry the source's travel scaled to the target's hip height.

const HIPS: String = "pelvis"
const LEAD_CHILDREN: Array[String] = ["neck_01", "spine_01", "middle_01_l", "middle_01_r", "calf_l", "calf_r"]

var _source: Skeleton3D
var _target: Skeleton3D
var _source_xf: Transform3D
var _target_xf: Transform3D
var _order: Array[int] = []  ## target bones, parents first
var _pair: Dictionary[int, int] = {}  ## target bone -> source bone
var _offset: Dictionary[int, Basis] = {}


func setup(source: Skeleton3D, source_xf: Transform3D, target: Skeleton3D, target_xf: Transform3D) -> void:
	_source = source
	_target = target
	_source_xf = source_xf
	_target_xf = target_xf
	for root: int in target.get_parentless_bones():
		_add_in_order(root)
	for bone: int in _order:
		var found: int = source.find_bone(target.get_bone_name(bone))
		if found >= 0:
			_pair[bone] = found
			_offset[bone] = PoseMatch.offset(_rest(source, source_xf, found).basis, _rest(target, target_xf, bone).basis,
				_direction(source, source_xf, found), _direction(target, target_xf, bone))


## Copies the source's current pose onto the target.
func apply() -> void:
	var globals: Dictionary[int, Transform3D] = {}
	for bone: int in _order:
		var parent: int = _target.get_bone_parent(bone)
		var parent_xf: Transform3D = globals[parent] if parent >= 0 else _target_xf
		var local: Transform3D = _target.get_bone_rest(bone)
		if _pair.has(bone):
			var now: Transform3D = _source_xf * _source.get_bone_global_pose(_pair[bone])
			var basis: Basis = now.basis.orthonormalized() * _offset[bone]
			local.basis = parent_xf.basis.orthonormalized().inverse() * basis
			if _target.get_bone_name(bone) == HIPS:
				var rest: Vector3 = _rest(_source, _source_xf, _pair[bone]).origin
				var spot: Vector3 = PoseMatch.hips(_rest(_target, _target_xf, bone).origin, rest, now.origin)
				local.origin = parent_xf.affine_inverse() * spot
			_target.set_bone_pose_rotation(bone, local.basis.get_rotation_quaternion())
			_target.set_bone_pose_position(bone, local.origin)
		globals[bone] = parent_xf * Transform3D(local.basis.orthonormalized(), local.origin)


func _add_in_order(bone: int) -> void:
	_order.append(bone)
	for child: int in _target.get_bone_children(bone):
		_add_in_order(child)


static func _rest(skeleton: Skeleton3D, xf: Transform3D, bone: int) -> Transform3D:
	return xf * skeleton.get_bone_global_rest(bone)


## Model-space rest direction from a bone to its lead child (a named one first, else the first child); zero for a leaf.
static func _direction(skeleton: Skeleton3D, xf: Transform3D, bone: int) -> Vector3:
	var children: PackedInt32Array = skeleton.get_bone_children(bone)
	if children.is_empty():
		return Vector3.ZERO
	var lead: int = children[0]
	for child: int in children:
		if LEAD_CHILDREN.has(skeleton.get_bone_name(child)):
			lead = child
	return _rest(skeleton, xf, lead).origin - _rest(skeleton, xf, bone).origin
