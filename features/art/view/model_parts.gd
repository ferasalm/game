class_name ModelParts
extends RefCounted
## Puts one ModelPartDef on a rig: hair or a rigid mesh from its glTF, a lathed garment, a sleeve capsule or the jambiyah, each on a
## BoneAttachment3D so it follows the bone through every animation. The offset and rotation of a part are in model
## space at the rest pose (y up, +z forward), converted here into the bone's own frame.


## The part's node (the attachment's child), or null when its scene is missing.
static func make(rig: ModelRig, part: ModelPartDef) -> Node3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = String(part.id) + "_at"
	attachment.bone_name = part.bone
	rig.skeleton.add_child(attachment)
	var rest: Transform3D = rig.rest_xform(part.bone)
	var node: Node3D = null
	var want := Transform3D(Basis.from_euler(part.rotation * (PI / 180.0)), rest.origin + part.offset)
	match part.kind:
		&"hair":
			node = _scene(rig, part.scene, part.texture, part.color)
			want = Transform3D.IDENTITY  # hair is modelled in model space already
		&"mesh":
			node = _scene(rig, part.scene, part.texture, part.color)
		&"lathe":
			node = _mesh(GarmentMesh.lathe(part.profile, part.length, part.depth, Color.WHITE, part.sweep), part, rig)
		&"limb":
			node = _limb(rig, part, rest)
			want = Transform3D.IDENTITY
		&"hilt":
			rig.hilt = HiltParts.new()
			node = rig.hilt.build(rig, part)
	if node == null:
		attachment.queue_free()
		return null
	node.name = String(part.id)
	attachment.add_child(node)
	if part.kind != &"limb":
		node.transform = rest.affine_inverse() * want
	return node


static func _mesh(mesh: Mesh, part: ModelPartDef, rig: ModelRig) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var mat: ShaderMaterial = ModelMaterials.skin(part.texture, part.color, false)
	rig.materials.append(mat)
	instance.material_override = mat
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance


static func _scene(rig: ModelRig, path: String, texture: String, color: Color) -> Node3D:
	return instance_scene(path, texture, color, false, rig.materials)


## A glTF scene with every mesh in one painted material (added to `materials`); null when the scene is missing.
static func instance_scene(path: String, texture: String, color: Color, hull: bool,
		materials: Array[ShaderMaterial]) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var node := packed.instantiate() as Node3D
	var mat: ShaderMaterial = ModelMaterials.skin(texture, color, hull)
	materials.append(mat)
	for mesh: Node in NodeScan.of_type(node, &"MeshInstance3D"):
		(mesh as MeshInstance3D).material_override = mat
	return node


## A capsule from the bone to its child bone, thickened by the part's radius (sleeves, trouser legs).
static func _limb(rig: ModelRig, part: ModelPartDef, rest: Transform3D) -> Node3D:
	var to: Vector3 = rig.rest_origin(part.to_bone)
	var span: Vector3 = to - rest.origin
	if span.length() < 0.01:
		return null
	var capsule := CapsuleMesh.new()
	capsule.radius = part.radius
	capsule.height = span.length() + part.radius * 2.0 * 0.6
	capsule.radial_segments = 10
	capsule.rings = 3
	var instance: MeshInstance3D = _mesh(capsule, part, rig)
	var up: Vector3 = span.normalized()
	var axis: Vector3 = Vector3.UP.cross(up)
	var basis: Basis = Basis.IDENTITY if axis.length() < 0.001 else Basis(axis.normalized(), Vector3.UP.angle_to(up))
	var mid: Vector3 = rest.origin + span * 0.5
	instance.transform = rest.affine_inverse() * Transform3D(basis, mid + part.offset)
	var holder := Node3D.new()
	holder.add_child(instance)
	return holder
