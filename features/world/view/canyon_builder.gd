class_name CanyonBuilder
extends RefCounted
## Builds the sunken street's walls (a stone base under brick, one box each, world-space textured so the courses
## line up) and the water channel in its middle. Walls hold the roofs' edge parapets up from far below; beyond
## the area they continue lower. No collision (nobody walks there) and no shadows.

const WALL_THICKNESS: float = 1.0
const PALETTE_ID: StringName = &"main"


static func build(spec: CanyonSpec) -> Node3D:
	var root := Node3D.new()
	root.name = "Canyon"
	var palette := ContentDB.get_def("palette", PALETTE_ID) as PaletteDef
	var stone: Material = SurfaceMaterials.tile(spec.base_pattern, palette)
	var brick: Material = SurfaceMaterials.tile(spec.wall_pattern, palette)
	var segments: Array[Vector3] = [
		Vector3(spec.z0, spec.z1, spec.top_y),
		Vector3(spec.z0 - spec.extend, spec.z0, spec.ext_top_y),
		Vector3(spec.z1, spec.z1 + spec.extend, spec.ext_top_y)]
	var sides: Array[float] = [spec.x0 - WALL_THICKNESS / 2.0, spec.x1 + WALL_THICKNESS / 2.0]
	for seg: Vector3 in segments:
		for cx: float in sides:
			_wall(root, cx, seg, spec, stone, brick)
	_channel(root, spec, palette)
	return root


static func _wall(root: Node3D, cx: float, seg: Vector3, spec: CanyonSpec, stone: Material, brick: Material) -> void:
	var base_top: float = minf(spec.bottom_y + spec.base_height, seg.z)
	_box(root, Vector3(cx, (spec.bottom_y + base_top) / 2.0, (seg.x + seg.y) / 2.0),
		Vector3(WALL_THICKNESS, base_top - spec.bottom_y, seg.y - seg.x), stone)
	if seg.z > base_top:
		_box(root, Vector3(cx, (base_top + seg.z) / 2.0, (seg.x + seg.y) / 2.0),
			Vector3(WALL_THICKNESS, seg.z - base_top, seg.y - seg.x), brick)


static func _channel(root: Node3D, spec: CanyonSpec, palette: PaletteDef) -> void:
	if spec.channel_width <= 0.0:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = palette.colors["k"]
	mat.emission_enabled = true
	mat.emission = spec.channel_color
	mat.emission_energy_multiplier = spec.channel_glow
	var z0: float = spec.z0 - spec.extend
	var z1: float = spec.z1 + spec.extend
	_box(root, Vector3((spec.x0 + spec.x1) / 2.0, spec.bottom_y + 0.04, (z0 + z1) / 2.0),
		Vector3(spec.channel_width, 0.08, z1 - z0), mat)


static func _box(root: Node3D, at: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
