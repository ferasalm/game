extends TestCase
## The painted arena: the def points at real content, the builder makes the roof, the parapet, the props, the lights
## and the city, the arena camera sits low with its own depth of field, and the party stands right, the enemies left.


func _def() -> ArenaDef:
	return ContentDB.get_def("arena", &"rooftop_arena") as ArenaDef


func _child(root: Node, node_name: String) -> Node:
	var found: Array[Node] = _children_named(root, node_name)
	return found[0] if not found.is_empty() else null


func _children_named(root: Node, node_name: String) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in root.get_children():
		if child.name.begins_with(node_name):
			out.append(child)
	return out


func test_def_uses_the_owners_look_and_real_content() -> void:
	var def: ArenaDef = _def()
	check(def != null, "rooftop_arena exists")
	check_eq(def.look, &"painted_b", "the arena wears the painted look the owner picked")
	check(ContentDB.get_def("tile", def.floor_tile) != null, "the roof tile exists")
	check(ContentDB.get_def("skyline", def.skyline) != null, "the city behind exists")
	check(not def.props.is_empty() and not def.lights.is_empty(), "it has props and lights")


func test_builder_makes_the_painted_roof_and_dressing() -> void:
	var def: ArenaDef = _def()
	var arena: Node3D = ArenaBuilder.build(def)
	check_eq(arena.position, def.origin, "the arena sits at its far origin")
	check_eq(_children_named(arena, "Roof").size(), 1, "one roof slab")
	check_eq(_children_named(arena, "Parapet").size(), 3, "a parapet on three sides (the fourth is the camera's)")
	var props: Node = _child(arena, "Props")
	check(props != null and _children_named(props, "Collision").is_empty(), "props stand, with no collision to walk into")
	check(_child(arena, "Skyline") != null, "the city stands behind")
	var roof := _child(arena, "Roof") as MeshInstance3D
	check(roof.position.y < 0.0 and is_equal_approx(roof.position.y + def.floor_size.y / 2.0, 0.0),
		"the slab's top face is at the origin height")
	var material: Material = ((roof.mesh as BoxMesh).material)
	check(material is ShaderMaterial, "the roof uses the painted world shader (not a flat standard material)")
	arena.free()


func test_the_arena_environment_is_its_own() -> void:
	var env: Environment = ArenaBuilder.environment(_def())
	check(env != null and env.background_mode == Environment.BG_SKY, "the arena has its own night sky environment")


func test_camera_is_low_with_its_own_depth_of_field() -> void:
	var def := ContentDB.get_def("battle_camera", &"default") as BattleCameraDef
	var pitch: float = rad_to_deg(atan((def.pos.y - def.look.y) / (def.pos.z - def.look.z)))
	check(pitch >= 10.0 and pitch <= 14.0, "about 12 degrees down (%.1f)" % pitch)
	check(def.dof_near > 0.0 and def.dof_far > def.dof_near and def.dof_amount > 0.0, "its own depth of field")
	var look := ContentDB.get_def("look", &"painted_b") as LookDef
	var camera := Diorama.make_camera(look)
	tree.root.add_child(camera)
	var rig := BattleCamera.new()
	tree.root.add_child(rig)
	rig.setup(camera, def, look, Vector3.ZERO, null, true)
	var practical := camera.attributes as CameraAttributesPractical
	check_eq(practical.dof_blur_far_distance, def.dof_far, "the rig applies the camera's far distance, not the look's")
	check_eq(practical.dof_blur_near_distance, def.dof_near, "and its near distance")
	rig.free()
	camera.free()


func test_party_stands_right_and_enemies_left() -> void:
	var view := ContentDB.get_def("battle_view", &"default") as BattleViewDef
	for slot: Vector2 in view.party_stage:
		check(slot.x > 0.0, "a party slot is on the right (x %.1f)" % slot.x)
	for slot: Vector2 in view.enemy_stage:
		check(slot.x < 0.0, "an enemy slot is on the left (x %.1f)" % slot.x)
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7, 0), Vector3.ZERO)
	var zayd: CharacterVisual = stage.fighters.visual(&"zayd")
	var foe: CharacterVisual = stage.fighters.visual(&"concession_enforcer_1")
	check(zayd != null and foe != null and zayd.position.x > foe.position.x, "Zayd stands to the right of the enforcer")
	check(stage.fighters.facing_of(0).x < 0.0 and stage.fighters.facing_of(1).x > 0.0,
		"the party faces left and the enemies face right")
	check(stage.fighters.facing_of(0).z > 0.0, "and both lean toward the camera (3/4)")
	stage.free()
