extends TestCase
## Rooftop actors: the workshop bench is a mesh, dialogue framing aims at the speaker's head, and Bilqis never sticks.

const DT: float = 1.0 / 60.0


func _save_dir() -> String:
	return SaveService.default_dir.path_join("rooftop")


func _make() -> Rooftop:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	rooftop.area_id = &"souq_rooftops_v4"
	tree.root.add_child(rooftop)
	return rooftop


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _begin() -> void:
	GameState.start_new()
	Router.save_dir = _save_dir()


func _end() -> void:
	SaveService.new(_save_dir()).delete(1)
	Router.save_dir = ""
	GameState.reset()
	PaintedMaterials.use(null)


func test_the_workshop_bench_is_a_mesh_and_the_seller_stands_behind_the_stall() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	var meshes: int = 0
	for child: Node in rooftop.workshop.get_children():
		meshes += 1 if child is MeshInstance3D else 0
	check_eq(meshes, 1, "the bench is a mesh")
	var visuals: int = 0
	for child: Node in rooftop.workshop.get_children():
		visuals += 1 if child is CharacterVisual else 0
	check_eq(visuals, 0, "and not a CharacterVisual")
	check(rooftop.frame_speaker(&"herb_seller"), "the seller can be framed by place id")
	check(rooftop.frame_speaker(&"abu_nabil"), "or by his picture id")
	check(not rooftop.frame_speaker(&"nobody"), "an unknown speaker is refused")
	rooftop.free()
	_end()


func test_dialogue_framing_aims_at_the_speaker_and_clears() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	var rig := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	check(rooftop.frame_speaker(&"bilqis"), "Bilqis can be framed")
	var framed: Vector3 = rooftop._aim.subject(rooftop.player.position)
	var want: float = clampf(rooftop.follower.position.x, rig.limit_x.x, rig.limit_x.y)
	check(is_equal_approx(framed.x, want), "the frame follows the speaker, inside the limits")
	check(framed.y > rooftop.follower.position.y, "and rises to her head")
	rooftop.clear_speaker()
	check(not rooftop._aim.is_framing(), "clearing returns to the player")
	rooftop.free()
	_end()


func test_bilqis_never_sticks_around_the_props() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	rooftop.player.position = Vector3(31.5, 0.0, 20.5)
	rooftop.follower.position = rooftop.player.position + Vector3(0.0, 0.0, 1.0)
	var route: Array[Vector3] = [Vector3(29.0, 0.0, 18.0), Vector3(29.0, 0.0, 16.0), Vector3(31.5, 0.0, 16.0),
		Vector3(33.5, 0.0, 18.0), Vector3(31.5, 0.0, 20.5)]
	for goal: Vector3 in route:
		for i: int in 600:
			var to: Vector3 = goal - rooftop.player.position
			if to.length() < 0.1:
				break
			rooftop.player._move(to.limit_length(_rules().walk_speed * DT))
			rooftop.follower._physics_process(DT)
		for i: int in 120:
			rooftop.follower._physics_process(DT)
		var gap: float = rooftop.follower.position.distance_to(rooftop.player.position)
		check(gap < _rules().follower_distance + 0.5, "Bilqis caught up at %s (gap %.2f)" % [goal, gap])
	rooftop.free()
	_end()


func test_follow_guard_snaps_when_wedged_or_too_far() -> void:
	var guard := FollowGuard.new(0.5, 4.0, 0.2)
	check(guard.update(DT, 5.0, 0.1, 0.1), "past the leash: snap")
	var snapped: bool = false
	for i: int in 40:
		snapped = snapped or guard.update(DT, 1.0, 0.1, 0.0)
	check(snapped, "wedged for the stuck time: snap")
	guard.reset()
	for i: int in 120:
		check(not guard.update(DT, 1.0, 0.1, 0.1), "making progress never snaps")
		if i > 3:
			break
