extends TestCase
## The rooftop scene builds headless; walking, the follower, the patrol touch, the ambush direction, the
## exploring switch, the patrol respawn, the workshop prompt and the camera. Time is driven by calling the
## nodes' _physics_process(delta) directly.

const DT: float = 1.0 / 60.0


func _make() -> Rooftop:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
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
	check_eq((hits[0] as Array)[0], &"rooftop_patrol", "the encounter id")
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


func test_reset_patrol_hides_for_the_respawn_time() -> void:
	var rooftop: Rooftop = _make()
	var hits: Array = _touches(rooftop)
	var respawn: float = _rules().patrol_respawn
	rooftop.reset_patrol()
	check(not rooftop.patrol.visible, "hidden right after reset")
	rooftop.player.position = rooftop.patrol.position
	rooftop.patrol._physics_process(respawn - 0.5)
	check(not rooftop.patrol.visible and hits.is_empty(), "still hidden and harmless before the time is up")
	rooftop.patrol._physics_process(1.0)
	check(rooftop.patrol.visible, "visible again after the respawn time")
	rooftop.patrol._physics_process(DT)
	check_eq(hits.size(), 1, "harmful again once it walks")
	rooftop.free()


func test_player_walks_faces_and_is_stopped_by_the_edge() -> void:
	var rooftop: Rooftop = _make()
	var start: Vector3 = rooftop.player.position
	_walk(rooftop, "move_right", 10)
	check(rooftop.player.position.x > start.x + 0.3, "walks right")
	check(rooftop.player.facing.x > 0.9, "remembers facing right")
	_walk(rooftop, "move_up", 10)
	check(rooftop.player.position.z < start.z - 0.3, "up is -Z")
	rooftop.player.position = Vector3(1.5, start.y, 15.5)
	_walk(rooftop, "move_left", 60)
	check(rooftop.player.position.x >= 1.2 and rooftop.player.position.x < 1.5, "the parapet blocks the west edge (x=%f)" % rooftop.player.position.x)
	rooftop.free()


func test_follower_trails_at_the_follower_distance() -> void:
	var rooftop: Rooftop = _make()
	_walk(rooftop, "move_right", 60)
	for i: int in 90:
		rooftop.follower._physics_process(DT)
	var gap: float = rooftop.follower.position.distance_to(rooftop.player.position)
	check(absf(gap - _rules().follower_distance) < 0.15, "follower is %f behind" % gap)
	check(rooftop.follower.position.x < rooftop.player.position.x, "and behind, not ahead")
	rooftop.free()


func test_workshop_prompt_and_interact() -> void:
	var rooftop: Rooftop = _make()
	var opened: Array = []
	rooftop.workshop_opened.connect(func() -> void: opened.append(true))
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	rooftop.workshop._physics_process(DT)
	check(not rooftop.workshop.prompt.visible, "no prompt far from the bench")
	rooftop.workshop._unhandled_input(press)
	check(opened.is_empty(), "interact does nothing far away")
	rooftop.player.position = rooftop.workshop.position + Vector3(0.5, 0.0, 0.0)
	rooftop.workshop._physics_process(DT)
	check(rooftop.workshop.prompt.visible, "prompt shows near the bench")
	check_eq(rooftop.workshop.prompt.text, "E: workshop", "prompt text comes from the localization key")
	rooftop.workshop._unhandled_input(press)
	check_eq(opened.size(), 1, "interact near the bench opens the workshop")
	rooftop.free()


func test_camera_follows_and_can_be_restored() -> void:
	var rooftop: Rooftop = _make()
	rooftop.player.position = Vector3(10.5, rooftop.player.position.y, 8.5)
	for i: int in 60:
		rooftop._process(0.1)
	var look := ContentDB.get_def("look", &"night") as LookDef
	var want: Vector3 = rooftop.player.position + look.camera_offset
	check(rooftop.camera.position.distance_to(want) < 0.05, "camera sits at the look offset from the player")
	var other := Camera3D.new()
	rooftop.add_child(other)
	other.make_current()
	check(not rooftop.camera.current, "another camera took over")
	rooftop.restore_camera()
	check(rooftop.camera.current, "restore_camera makes the follow camera current again")
	rooftop.free()


func test_debug_overlay_is_hidden_until_f3() -> void:
	var rooftop: Rooftop = _make()
	check(not rooftop._debug.visible, "players never see the FPS/debug overlay by default")
	var f3 := InputEventKey.new()
	f3.keycode = KEY_F3
	f3.pressed = true
	rooftop._debug._unhandled_key_input(f3)
	check(rooftop._debug.visible, "F3 shows it")
	rooftop._debug._unhandled_key_input(f3)
	check(not rooftop._debug.visible, "F3 again hides it")
	rooftop.free()
