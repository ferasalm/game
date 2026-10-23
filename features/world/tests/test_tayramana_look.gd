class_name TestTayramanaLook
extends TestCase
## purpose: Tests for Tayramana look pass: four walls, ceiling, qamariya arches, framed shots, warm lights, sit prompt.

const TAYRAMANA_ID: StringName = &"tayramana"


func _spec() -> RoomDef:
	return ContentDB.get_def("room", TAYRAMANA_ID) as RoomDef


func _palette() -> PaletteDef:
	return ContentDB.get_def("palette", &"main") as PaletteDef


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _rig() -> CameraRigDef:
	return ContentDB.get_def("camera_rig", &"explore") as CameraRigDef


func _clean() -> void:
	PaintedMaterials.use(null)
	PropMesh.clear()
	SurfaceMaterials.clear()


func _find_child_node(parent: Node, child_name: String) -> Node:
	for child: Node in parent.get_children():
		if child.name == child_name:
			return child
	return null


func test_four_walls_and_ceiling_exist() -> void:
	var def: RoomDef = _spec()
	var node: Node3D = RoomBuilder.build(def, _palette())
	check(node != null, "room built successfully")
	var shell: Node3D = _find_child_node(node, "RoomShell") as Node3D
	check(shell != null, "RoomShell exists")
	check(_find_child_node(shell, "Floor") != null, "Floor exists")
	check(_find_child_node(shell, "Ceiling") != null, "Ceiling exists")
	var ceiling: Node = _find_child_node(shell, "Ceiling")
	check(ceiling.get_child_count() > 1, "Ceiling has slab and wood beams")
	var walls: Node = _find_child_node(shell, "Walls")
	check(walls != null, "Walls container exists")
	check(_find_child_node(walls, "North") != null, "North wall exists")
	check(_find_child_node(walls, "South") != null, "South wall exists")
	check(_find_child_node(walls, "East") != null, "East wall exists")
	check(_find_child_node(walls, "West") != null, "West wall exists")
	node.free()
	_clean()


func test_three_qamariya_arches_with_seven_emissive_segments() -> void:
	var def: RoomDef = _spec()
	var node: Node3D = RoomBuilder.build(def, _palette())
	var shell: Node3D = _find_child_node(node, "RoomShell") as Node3D
	var qamariyas: Node = _find_child_node(shell, "Qamariyas")
	check(qamariyas != null, "Qamariyas node exists")
	var arch_names: Array[String] = ["North", "East", "West"]
	for arch_name: String in arch_names:
		var mi: MeshInstance3D = _find_child_node(qamariyas, arch_name) as MeshInstance3D
		check(mi != null, "Arch %s exists" % arch_name)
		var mesh: Mesh = mi.mesh
		check(mesh != null, "Arch %s has mesh" % arch_name)
		var arrays: Array = mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var segments: int = vertices.size() / 3
		check_eq(segments, 7, "Arch %s has 7 segments" % arch_name)
		var mat: Material = mesh.surface_get_material(0)
		check(mat == PaintedMaterials.glow(), "Arch %s uses emissive glow material" % arch_name)
	node.free()
	_clean()


func test_framed_shots_differ_and_look_at_different_walls() -> void:
	var def: RoomDef = _spec()
	check_eq(def.shots.size(), 2, "two framed camera shots exist")
	var s0: RoomDef.Shot = def.shots[0]
	var s1: RoomDef.Shot = def.shots[1]
	var pos_dist: float = (s0.cam_pos - s1.cam_pos).length()
	check(pos_dist >= 3.0, "shots differ in position by >= 3 m (dist = %.2f m)" % pos_dist)
	var dir0: Vector3 = (s0.look_target - s0.cam_pos).normalized()
	var dir1: Vector3 = (s1.look_target - s1.cam_pos).normalized()
	check(dir0.z < 0.0, "shot_door looks north toward window wall (dir.z = %.2f)" % dir0.z)
	check(dir1.z > 0.0, "shot_window looks south toward door wall (dir.z = %.2f)" % dir1.z)
	check(s0.look_target.y >= 0.6 and s0.look_target.y <= 1.0, "shot_door frames seated party at chest height")
	check(s1.look_target.y >= 0.6 and s1.look_target.y <= 1.0, "shot_window frames seated party at chest height")


func test_lamp_lights_exist_and_are_warm() -> void:
	var room := TayramanaRoom.new(_rules(), _spec(), _palette(), _rig())
	var lamps: Array[OmniLight3D] = []
	for child: Node in room.get_children():
		if child is OmniLight3D:
			lamps.append(child as OmniLight3D)
	check(lamps.size() >= 2, "at least two OmniLight3D lamps exist (found %d)" % lamps.size())
	for lamp: OmniLight3D in lamps:
		var c: Color = lamp.light_color
		var warm: bool = c.r > 0.8 and c.r > c.g and c.g > c.b
		check(warm, "lamp %s is warm amber (color: %s)" % [lamp.name, c.to_html()])
	room.free()
	_clean()


func test_no_prompt_visible_while_seated() -> void:
	var room := TayramanaRoom.new(_rules(), _spec(), _palette(), _rig())
	tree.root.add_child(room)
	check(room.sit_spots.size() >= 2, "room has sit spots")
	room.sit_party(true)
	for spot: RoomSitSpot in room.sit_spots:
		check(not spot.prompt.visible, "sit prompt is hidden while seated: %s" % spot.spot_id)
	room.sit_party(false)
	for spot: RoomSitSpot in room.sit_spots:
		check(spot._active, "sit spot is active again when standing: %s" % spot.spot_id)
	room.queue_free()
	_clean()
