extends TestCase
## The rooftop scene builds headless; walking, the follower, the patrol touch, the ambush direction, the
## exploring switch, the patrol respawn and parapet collision. Time is driven by calling _physics_process(delta).

const DT: float = 1.0 / 60.0


func _make() -> Rooftop:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	rooftop.area_id = &"souq_rooftops_v4"
	rooftop.look_id = &"night"
	tree.root.add_child(rooftop)
	return rooftop


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _touches(rooftop: Rooftop) -> Array:
	var hits: Array = []
	rooftop.encounter_touched.connect(func(id: StringName, behind: bool) -> void: hits.append([id, behind]))
	return hits


func _walk(rooftop: Rooftop, action: String, frames: int) -> void:
	Input.action_press(action)
	for i: int in frames:
		rooftop.player._physics_process(DT)
		rooftop.follower._physics_process(DT)
	Input.action_release(action)


func test_builds_with_actors() -> void:
	var rooftop: Rooftop = _make()
	check(rooftop.player != null and rooftop.follower != null, "player and follower exist")
	check(rooftop.patrol != null and rooftop.workshop != null, "patrol and workshop exist")
	var multimeshes: int = 0
	var bodies: int = 0
	for child: Node in rooftop.blocks.get_children():
		multimeshes += 1 if child is MultiMeshInstance3D else 0
		bodies += 1 if child is StaticBody3D else 0
	check(multimeshes >= 5, "one MultiMeshInstance3D per drawn tile type (%d)" % multimeshes)
	check_eq(bodies, 1, "one static body for all collision")
	check(rooftop.camera.current, "the follow camera is current")
	rooftop.free()


func test_touch_fires_once() -> void:
	var rooftop: Rooftop = _make()
	var hits: Array = _touches(rooftop)
	rooftop.patrol.position = rooftop.player.position + Vector3(0.3, 0.0, 0.0)
	rooftop.patrol._physics_process(DT)
	rooftop.patrol._physics_process(DT)
	check_eq(hits.size(), 1, "exactly one touch")
	check_eq((hits[0] as Array)[0], rooftop.patrol.encounter_id, "the touching patrol's encounter id")
	check(rooftop.battle_anchor().distance_to(rooftop.player.position) < 1.0, "anchor is where the touch happened")
	rooftop.free()


func test_from_behind_when_facing_away() -> void:
	var rooftop: Rooftop = _make()
	var hits: Array = _touches(rooftop)
	rooftop.player.facing = Vector3(-1.0, 0.0, 0.0)
	rooftop.patrol.position = rooftop.player.position + Vector3(0.3, 0.0, 0.0)
	rooftop.patrol._physics_process(DT)
	check_eq((hits[0] as Array)[1], true, "facing away: from behind")
	rooftop.free()


func test_not_from_behind_when_facing_it() -> void:
	var rooftop: Rooftop = _make()
	var hits: Array = _touches(rooftop)
	rooftop.player.facing = Vector3(1.0, 0.0, 0.0)
	rooftop.patrol.position = rooftop.player.position + Vector3(0.3, 0.0, 0.0)
	rooftop.patrol._physics_process(DT)
	check_eq((hits[0] as Array)[1], false, "facing it: not from behind")
	rooftop.free()


func test_set_exploring_off_stops_everything() -> void:
	var rooftop: Rooftop = _make()
	var hits: Array = _touches(rooftop)
	rooftop.set_exploring(false)
	check(not rooftop.player.visible and not rooftop.follower.visible and not rooftop.patrol.visible, "all hidden")
	var before: Vector3 = rooftop.player.position
	_walk(rooftop, "move_right", 5)
	check_eq(rooftop.player.position, before, "the player ignores input while not exploring")
	rooftop.patrol.position = rooftop.player.position
	rooftop.patrol._physics_process(DT)
	check(hits.is_empty(), "no touch while not exploring")
	rooftop.set_exploring(true)
	check(rooftop.player.visible and rooftop.patrol.visible, "everything shows again")
	rooftop.patrol._physics_process(DT)
	check_eq(hits.size(), 1, "a touch fires after exploring resumes")
	rooftop.free()


func test_no_second_touch_until_exploring_resumes() -> void:
	var rooftop: Rooftop = _make()
	var hits: Array = _touches(rooftop)
	rooftop.patrol.position = rooftop.player.position
	rooftop.patrol._physics_process(DT)
	rooftop.set_exploring(false)
	rooftop.set_exploring(true)
	rooftop.patrol._physics_process(DT)
	check_eq(hits.size(), 2, "the lock is released by set_exploring(true)")
	rooftop.free()


func test_reset_patrol_gives_a_grace_time_without_touch() -> void:
	var rooftop: Rooftop = _make()
	var hits: Array = _touches(rooftop)
	var grace: float = _rules().touch_grace
	rooftop.reset_patrol()
	check(rooftop.patrol.visible, "a patrol that was not beaten stays in play")
	rooftop.patrol.position = rooftop.player.position
	rooftop.patrol._physics_process(grace - 0.5)
	check(hits.is_empty(), "harmless while the grace time runs")
	rooftop.patrol._physics_process(1.0)
	rooftop.patrol.position = rooftop.player.position
	rooftop.patrol._physics_process(DT)
	check_eq(hits.size(), 1, "harmful again after it")
	rooftop.free()


func test_player_walks_faces_and_is_stopped_by_the_edge() -> void:
	var rooftop: Rooftop = _make()
	var start: Vector3 = rooftop.player.position
	_walk(rooftop, "move_right", 10)
	check(rooftop.player.position.x > start.x + 0.3, "walks right")
	check(rooftop.player.facing.x > 0.9, "remembers facing right")
	_walk(rooftop, "move_up", 10)
	check(rooftop.player.position.z < start.z - 0.3, "up is -Z")
	rooftop.player.position = Vector3(27.5, 0.0, 20.5)
	_walk(rooftop, "move_left", 60)
	check(rooftop.player.position.x >= 27.2 and rooftop.player.position.x < 27.5, "the parapet blocks the west edge")
	rooftop.free()
