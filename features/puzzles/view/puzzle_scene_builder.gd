class_name PuzzleSceneBuilder
extends RefCounted
## purpose: Builds the fixed parts of the puzzle yard scene: camera, light, environment, player, marker and hints.


static func build_yard(parent: Node3D, yard: PuzzleYardDef) -> void:
	PuzzleYardBuilder.build(parent, yard)


static func build_player(parent: Node3D, yard: PuzzleYardDef) -> PuzzlePlayer:
	var node := PuzzlePlayer.new()
	parent.add_child(node)
	node.setup(yard)
	return node


static func build_marker(parent: Node3D, yard: PuzzleYardDef) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = yard.marker_radius
	sphere.height = yard.marker_radius * 2.0
	var marker := MeshInstance3D.new()
	marker.mesh = sphere
	marker.material_override = PuzzleMaterials.emissive(yard.marker_color, 1.5)
	marker.visible = false
	parent.add_child(marker)
	return marker


static func build_camera(parent: Node3D, yard: PuzzleYardDef) -> Camera3D:
	var camera := Camera3D.new()
	camera.transform = Transform3D(Basis.looking_at(yard.camera_look_at - yard.camera_at, Vector3.UP),
		yard.camera_at)
	camera.fov = yard.camera_fov
	parent.add_child(camera)
	camera.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.light_energy = 1.2
	parent.add_child(sun)
	var env := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = Color("#1a1c22")
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("#8890a0")
	world.ambient_light_energy = 0.9
	env.environment = world
	parent.add_child(env)
	return camera


static func build_hints(parent: Node3D, yard: PuzzleYardDef, light_def: LightLockDef,
		water_def: WaterNetDef) -> PuzzleHintsView:
	var hints := PuzzleHintsView.new()
	parent.add_child(hints)
	hints.setup(yard, light_def, water_def)
	return hints
