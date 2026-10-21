class_name OcclusionFade
extends Node
## The camera cut-away (painted looks): when a building or prop stands between the camera and the party, a tube from
## the camera to the party dithers away in the painted world shaders (occlusion_dither.gdshaderinc). This node finds
## the tall painted blocks once (instance boxes), tests the camera-party line against them each frame (SegmentBox),
## eases the fade amount toward 1 (blocked) or 0 (clear) and writes the global shader uniforms. When its camera is not
## the current one (a battle arena is showing) the cut eases out, so other scenes are never cut by stale numbers.

const G_CAM: StringName = &"occ_cam"
const G_TARGET: StringName = &"occ_target"
const G_SHAPE: StringName = &"occ_shape"
const SHADER: Shader = preload("res://features/world/view/shaders/painted_world.gdshader")

var amount: float = 0.0
var blocked: bool = false

var _paint: PaintDef
var _camera: Camera3D
var _target: Node3D
var _boxes: Array[AABB] = []


## Adds the cut-away to root for this camera and party node (the camera and target must be in the tree).
static func attach(root: Node, camera: Camera3D, target: Node3D, paint: PaintDef) -> OcclusionFade:
	var fade := OcclusionFade.new()
	fade.name = "OcclusionFade"
	fade.setup(root, camera, target, paint)
	root.add_child(fade)
	return fade


func setup(root: Node, camera: Camera3D, target: Node3D, paint: PaintDef) -> void:
	_paint = paint
	_camera = camera
	_target = target
	var floor_y: float = target.global_position.y
	_boxes = collect_boxes(root, floor_y, paint.occlude_min_height)
	process_priority = 100  # after the camera rig has moved this frame
	RenderingServer.global_shader_parameter_set(G_SHAPE, Vector4(paint.occlude_soft, paint.occlude_margin, floor_y + paint.occlude_floor, 0.0))


## Boxes of every tall block under root drawn with the painted world shader.
static func collect_boxes(root: Node, floor_y: float, min_height: float) -> Array[AABB]:
	var out: Array[AABB] = []
	for node: Node in root.find_children("*", "GeometryInstance3D", true, false):
		var mesh: Mesh = null
		var transforms: Array[Transform3D] = []
		if node is MultiMeshInstance3D:
			var multi: MultiMesh = (node as MultiMeshInstance3D).multimesh
			mesh = multi.mesh
			for i: int in multi.instance_count:
				transforms.append((node as Node3D).global_transform * multi.get_instance_transform(i))
		elif node is MeshInstance3D:
			mesh = (node as MeshInstance3D).mesh
			transforms.append((node as Node3D).global_transform)
		if mesh != null and _is_painted(mesh):
			out.append_array(SegmentBox.boxes_of(mesh.get_aabb(), transforms, floor_y, min_height))
	return out


func box_count() -> int:
	return _boxes.size()


func _process(delta: float) -> void:
	if _camera == null or _target == null or not is_instance_valid(_camera):
		return
	var focus: Vector3 = _target.global_position + Vector3(0.0, _paint.occlude_focus, 0.0)
	var eye: Vector3 = _camera.global_position
	var live: bool = _camera.is_current() and _target.is_visible_in_tree()
	blocked = live and is_blocked(eye, focus)
	amount = SegmentBox.eased(amount, 1.0 if blocked else 0.0, _paint.occlude_speed, delta)
	RenderingServer.global_shader_parameter_set(G_CAM, Vector4(eye.x, eye.y, eye.z, amount))
	RenderingServer.global_shader_parameter_set(G_TARGET, Vector4(focus.x, focus.y, focus.z, _paint.occlude_radius))


## Is a tall block across the camera-party line (stopping the margin short of the party)?
func is_blocked(eye: Vector3, focus: Vector3) -> bool:
	var stop: Vector3 = focus + (eye - focus).normalized() * _paint.occlude_margin
	return SegmentBox.any_hit(eye, stop, _boxes, _paint.occlude_radius * 0.5)


func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set(G_CAM, Vector4.ZERO)


static func _is_painted(mesh: Mesh) -> bool:
	for surface: int in mesh.get_surface_count():
		var mat := mesh.surface_get_material(surface) as ShaderMaterial
		if mat != null and mat.shader == SHADER:
			return true
	return false
