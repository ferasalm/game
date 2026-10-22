extends TestCase
## Feras's Rodin pieces after tools/rodin: Zayd's baked dagger is pressed flat onto his chest (the code hilt is his
## only jambiyah), the grandfather's hilt is the Rodin grip above the belt origin and the Rodin sheath below it curving
## forward (the blade stays the code one), and the survey drone's hull is the Rodin mesh at hover height.

const DAGGER_BOX := AABB(Vector3(-0.12, 0.98, 0.156), Vector3(0.23, 0.38, 0.3))


func test_zayds_baked_dagger_is_pressed_flat() -> void:
	var scene := (load("res://assets/characters/zayd_rodin.glb") as PackedScene).instantiate()
	var meshes: Array[Node] = NodeScan.of_type(scene, &"MeshInstance3D")
	check_eq(meshes.size(), 1, "one body mesh")
	var points: PackedVector3Array = (meshes[0] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var ahead: int = 0
	for p: Vector3 in points:
		if DAGGER_BOX.has_point(p):
			ahead += 1
	check_eq(ahead, 0, "no vertex of the baked dagger stands out of the chest")
	scene.free()


func test_the_grandfathers_hilt_is_the_rodin_grip_and_sheath() -> void:
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var rig := ModelRig.new()
	check(rig.build(ContentDB.get_def("model", &"zayd") as ModelDef, holder), "zayd builds")
	var hilt: HiltParts = rig.hilt
	var grip: Node3D = hilt.hilt.get_child(0)
	var sheath: Node3D = hilt.root.get_child(0)
	check(not grip is MeshInstance3D and not sheath is MeshInstance3D, "grip and sheath are the Rodin scenes")
	check(hilt.blade.mesh != null, "the blade is still the code one")
	var g: AABB = _bounds(grip, hilt.hilt)
	var s: AABB = _bounds(sheath, hilt.root)
	check(g.position.y > -0.01 and g.end.y > 0.09 and g.end.y < 0.14, "the grip rises ~0.12 m from the origin: %s" % g)
	check(s.end.y < 0.01 and s.position.y < -0.15, "the sheath hangs below it: %s" % s)
	check(s.end.z > 0.1, "the sheath curves forward (+z), as the code blade does: %s" % s)
	holder.free()


func test_the_drone_hull_is_the_rodin_mesh() -> void:
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var rig := RigidRig.new()
	rig.build(ContentDB.get_def("model", &"survey_drone") as ModelDef, holder)
	check_eq(rig.root.get_child_count(), 1, "one part: the hull")
	var hull: Node3D = rig.root.get_child(0)
	var box: AABB = _bounds(hull, rig.root)
	check(not NodeScan.of_type(hull, &"MeshInstance3D").is_empty(), "the hull is a glb scene")
	check(box.size.x > 0.6 and box.size.x < 1.0, "about 0.85 m wide with its pods: %s" % box)
	check(absf(box.get_center().y - 1.0) < 0.1, "hovering at its offset: %s" % box)
	holder.free()


## The meshes under `node` in the frame of `frame`.
func _bounds(node: Node3D, frame: Node3D) -> AABB:
	var out := AABB()
	var first: bool = true
	for found: Node in NodeScan.of_type(node, &"MeshInstance3D"):
		var mesh := found as MeshInstance3D
		var box: AABB = (frame.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out
