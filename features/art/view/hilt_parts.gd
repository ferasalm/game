class_name HiltParts
extends RefCounted
## The grandfather's jambiyah as nodes (HiltMesh draws it): a sheath and the hilt with its blade sit at the belt
## (`root`); draw() carries the hilt to the hand bone for a strike (the blade shows, the sheath stays), sheathe() puts it
## back. `top` and `tip` mark the hilt and the blade's point for the weapon trail.

var root: Node3D
var hilt: Node3D
var blade: MeshInstance3D
var top: Node3D
var tip: Node3D
var drawn: bool = false
var _hand: BoneAttachment3D
var _hand_local: Transform3D = Transform3D.IDENTITY


## Builds the pieces on the rig; returns the node that rides the belt bone.
func build(rig: ModelRig, part: ModelPartDef) -> Node3D:
	var made: Dictionary = HiltMesh.build(part)
	root = Node3D.new()
	root.add_child(_instance(made[&"sheath"] as Mesh, rig))
	hilt = Node3D.new()
	hilt.name = "hilt"
	hilt.add_child(_instance(made[&"hilt"] as Mesh, rig))
	blade = _instance(made[&"blade"] as Mesh, rig)
	blade.visible = false
	hilt.add_child(blade)
	top = _marker(made[&"top"] as Vector3)
	tip = _marker(made[&"tip"] as Vector3)
	root.add_child(hilt)
	_hand = BoneAttachment3D.new()
	_hand.name = "hilt_hand"
	_hand.bone_name = part.draw_bone
	rig.skeleton.add_child(_hand)
	var rest: Transform3D = rig.rest_xform(part.draw_bone)
	var want := Transform3D(Basis.from_euler(part.draw_rotation * (PI / 180.0)), rest.origin + part.draw_offset)
	_hand_local = rest.affine_inverse() * want
	return root


## Moves the hilt to the hand and bares the blade.
func draw() -> void:
	if drawn:
		return
	drawn = true
	root.remove_child(hilt)
	_hand.add_child(hilt)
	hilt.transform = _hand_local
	blade.visible = true


## Back in the sheath at the belt.
func sheathe() -> void:
	if not drawn:
		return
	drawn = false
	_hand.remove_child(hilt)
	root.add_child(hilt)
	hilt.transform = Transform3D.IDENTITY
	blade.visible = false


func _instance(mesh: Mesh, rig: ModelRig) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var mat: ShaderMaterial = ModelMaterials.skin("", Color.WHITE, true)
	rig.materials.append(mat)
	instance.material_override = mat
	return instance


func _marker(at: Vector3) -> Node3D:
	var marker := Node3D.new()
	marker.position = at
	hilt.add_child(marker)
	return marker
