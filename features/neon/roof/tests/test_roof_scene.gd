class_name TestRoofScene
extends TestCase
## purpose: headless tests for RoofScene (spawning, sliding, guard patrols, battle request, exit cable).

func _make_roof() -> RoofScene:
	var scene := load("res://features/neon/roof/roof_scene.tscn") as PackedScene
	var roof := scene.instantiate() as RoofScene
	tree.root.add_child(roof)
	return roof


func test_hero_spawns_at_room_spawn() -> void:
	var roof := _make_roof()
	check(roof.hero() != null, "hero exists")
	check(roof.room() != null, "room def loaded")
	check_eq(roof.hero().position, roof.room().spawn, "hero spawns at room.spawn")
	roof.queue_free()


func test_step_into_wall_slides() -> void:
	var roof := _make_roof()
	var spawn: Vector2 = roof.room().spawn
	# Big step upward towards wall
	var candidate_step := Vector2(20.0, -80.0)
	var stepped: Vector2 = IsoWalk.step(spawn, candidate_step, roof.room().walk, roof.room().holes)
	check(IsoWalk.can_stand(stepped, roof.room().walk, roof.room().holes), "stepped position is on floor")
	check(stepped != spawn, "hero slid along the wall rather than freezing completely")
	roof.queue_free()


func test_guards_walk_their_paths() -> void:
	var roof := _make_roof()
	var guards: Array[IsoActor] = roof.guards()
	check_eq(guards.size(), 2, "two guards patrol")
	var start_pos_0: Vector2 = guards[0].position
	var start_pos_1: Vector2 = guards[1].position
	for i: int in 10:
		roof._process(0.1)
	check(guards[0].position != start_pos_0, "guard 0 advanced along path")
	check(guards[1].position != start_pos_1, "guard 1 advanced along path")
	roof.queue_free()


func test_touching_guard_requests_battle_once() -> void:
	var roof := _make_roof()
	var battle_emitted: Array[Dictionary] = []
	roof.battle_requested.connect(func(foes: Array[IsoActor], contact: Vector2, ambush: bool) -> void:
		battle_emitted.append({"foes": foes, "contact": contact, "ambush": ambush})
	)
	var target_guard: IsoActor = roof.guards()[0]
	# Place hero behind guard within 70 px
	var guard_facing_vec: Vector2 = IsoDir.vector(target_guard.facing)
	roof.hero().position = target_guard.position - guard_facing_vec * 40.0
	roof._process(0.016)
	check_eq(battle_emitted.size(), 1, "battle_requested emitted on touch")
	if battle_emitted.size() > 0:
		var req: Dictionary = battle_emitted[0]
		check_eq((req["foes"] as Array).size(), 2, "battle request includes all living guards")
		check(req["ambush"], "approaching from behind is ambush")
		var expected_midpoint: Vector2 = (roof.hero().position + target_guard.position) * 0.5
		check_eq(req["contact"], expected_midpoint, "contact point is midpoint")
	# Step again; battle_requested must NOT fire a second time
	roof._process(0.016)
	check_eq(battle_emitted.size(), 1, "battle_requested fires only once")
	roof.queue_free()


func test_cable_line_before_and_after_mark_won() -> void:
	var roof := _make_roof()
	var exited_events: Array[bool] = []
	roof.exited.connect(func() -> void: exited_events.append(true))
	var cable_pos: Vector2 = Vector2.ZERO
	for item: Dictionary in roof.room().interactables:
		if String(item["id"]) == "cable_line":
			cable_pos = item["pos"]
	check(cable_pos != Vector2.ZERO, "cable_pos found: %s" % cable_pos)
	roof.hero().position = cable_pos
	roof.interact()
	check_eq(exited_events.size(), 0, "cable line does nothing before mark_won")
	roof.mark_won()
	roof.interact()
	check_eq(exited_events.size(), 1, "cable line emits exited after mark_won")
	roof.queue_free()


func test_guards_stop_patrolling_after_the_fight() -> void:
	var roof := _make_roof()
	var guard: IsoActor = roof.guards()[0]
	roof.hero().position = guard.position - IsoDir.vector(guard.facing) * 40.0
	roof._process(0.016)
	roof.mark_won()
	roof.set_exploring(true)
	var held: Vector2 = guard.position
	for i: int in 10:
		roof._process(0.1)
	check_eq(guard.position, held, "a fought guard no longer walks its path")
	check(roof.world() != null and guard.get_parent() == roof.world(), "world() holds the actors")
	roof.queue_free()
