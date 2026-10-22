class_name ModelRig
extends RefCounted
## Builds one skinned character under a holder node from its ModelDef: the glTF body (scaled to height_m), its
## painted materials, the parts it wears on BoneAttachment3D nodes, and a MANUAL AnimationPlayer that carries the
## shared Quaternius animation library (the same 65-bone rig as the stand-in bodies; a body with other bone axes names
## a `pose_source` that plays the clips hidden and PoseFollow retargets; the library scene is loaded once and only its
## AnimationLibrary is kept). Part offsets are in model space at the rest pose from the
## bone, so a part is authored with y up and +z forward whatever the bone's own axes are.

const LIBRARY_SCENE: String = "res://assets/characters/ual1_standard.glb"
const BROWS: String = "Eyebrows"
const EYES: String = "Eyes"
static var _library: AnimationLibrary = null

var def: ModelDef
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var materials: Array[ShaderMaterial] = []
var parts: Dictionary[StringName, Node3D] = {}
var hilt: HiltParts = null  ## the grandfather's jambiyah, when the model wears it
var native_height: float = 1.8
var anim_root: Node3D  ## where the AnimationPlayer's tracks start: the model, or the hidden pose source
var anim_skeleton: Skeleton3D
var pose: PoseFollow = null
var _skeleton_xf: Transform3D = Transform3D.IDENTITY


## The animation library of the Quaternius Universal Animation Library (cached; null when the file is missing).
static func library() -> AnimationLibrary:
	if _library == null:
		var packed := load(LIBRARY_SCENE) as PackedScene
		if packed == null:
			return null
		var scene: Node = packed.instantiate()
		var found: Array[Node] = NodeScan.of_type(scene, &"AnimationPlayer")
		if not found.is_empty():
			_library = (found[0] as AnimationPlayer).get_animation_library(&"")
		scene.free()
	return _library


## Builds the model under `holder`; false when the scene or its skeleton is missing.
func build(model_def: ModelDef, holder: Node3D) -> bool:
	def = model_def
	var packed := load(def.scene) as PackedScene
	if packed == null:
		return false
	model = packed.instantiate() as Node3D
	var skeletons: Array[Node] = NodeScan.of_type(model, &"Skeleton3D")
	if skeletons.is_empty():
		model.free()
		return false
	skeleton = skeletons[0] as Skeleton3D
	_skeleton_xf = NodeScan.transform_of(model, skeleton)
	holder.add_child(model)
	_measure()
	model.scale = Vector3.ONE * (def.height_m / native_height)
	holder.scale = Vector3(def.girth, 1.0, def.girth)
	_paint_body()
	for part: ModelPartDef in def.parts:
		var made: Node3D = ModelParts.make(self, part)
		if made != null:
			parts[part.id] = made
	anim_root = model
	anim_skeleton = skeleton
	if not def.pose_source.is_empty() and not _add_pose_source(holder):
		return false
	player = AnimationPlayer.new()
	anim_root.add_child(player)
	player.root_node = NodePath("..")
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.add_animation_library(&"", library())
	return true


## Moves the body to the pose source's current pose, left-right mirrored when asked (call after every advance; nothing
## without a pose source).
func follow(mirrored: bool = false) -> void:
	if pose != null:
		pose.apply(mirrored)


## The hidden body that plays the clips for a `pose_source` model; false when its scene or skeleton is missing.
func _add_pose_source(holder: Node3D) -> bool:
	var packed := load(def.pose_source) as PackedScene
	if packed == null:
		return false
	anim_root = packed.instantiate() as Node3D
	var skeletons: Array[Node] = NodeScan.of_type(anim_root, &"Skeleton3D")
	if skeletons.is_empty():
		anim_root.free()
		return false
	anim_skeleton = skeletons[0] as Skeleton3D
	anim_root.visible = false
	holder.add_child(anim_root)
	pose = PoseFollow.new()
	pose.setup(anim_skeleton, NodeScan.transform_of(anim_root, anim_skeleton), skeleton, _skeleton_xf)
	return true


## A bone's rest position in model space (metres, before the model's own scale).
func rest_origin(bone: String) -> Vector3:
	return rest_xform(bone).origin


func rest_xform(bone: String) -> Transform3D:
	var index: int = skeleton.find_bone(bone)
	if index < 0:
		return Transform3D.IDENTITY
	return _skeleton_xf * skeleton.get_bone_global_rest(index)


## Where a bone is now, in the model node's own space.
func bone_position(bone: String) -> Vector3:
	var index: int = skeleton.find_bone(bone)
	if index < 0:
		return Vector3.ZERO
	return (_skeleton_xf * skeleton.get_bone_global_pose(index)).origin


func _measure() -> void:
	var top: float = 0.0
	for mesh: Node in NodeScan.of_type(model, &"MeshInstance3D"):
		var instance := mesh as MeshInstance3D
		if instance.name != BROWS and instance.name != EYES:
			top = maxf(top, (NodeScan.transform_of(model, instance) * instance.get_aabb()).end.y)
	native_height = maxf(top, 0.1)


func _paint_body() -> void:
	var skin: ShaderMaterial = ModelMaterials.skin(def.skin, def.tint, def.outline_hull)
	materials.append(skin)
	for mesh: Node in NodeScan.of_type(model, &"MeshInstance3D"):
		var instance := mesh as MeshInstance3D
		var made: ShaderMaterial = skin
		if instance.name == EYES:
			made = ModelMaterials.skin(def.eye_texture, Color.WHITE, false)
			materials.append(made)
		elif instance.name == BROWS:
			made = ModelMaterials.skin(def.hair_texture, def.brow_color, false)
			materials.append(made)
		for surface: int in instance.mesh.get_surface_count():
			instance.set_surface_override_material(surface, made)
