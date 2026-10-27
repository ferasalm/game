extends TestCase
## Feras's Rodin pieces after tools/rodin: the grandfather's hilt is the Rodin grip above the belt origin and the
## Rodin sheath below it curving forward (the blade stays the code one).


func test_the_grandfathers_hilt_is_the_rodin_grip_and_sheath() -> void:
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var rig := ModelRig.new()
	check(rig.build(ContentDB.get_def("model", &"rydan") as ModelDef, holder), "rydan builds")
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
