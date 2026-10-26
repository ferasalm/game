class_name TestNeonFoundation
extends TestCase
## purpose: Neon Glitch foundation: the sprite sets and the prison roof load with real sheets, IsoDir maps screen
## directions to the baked rows and back, IsoWalk keeps feet on the floor and slides along walls, IsoActor plays,
## signals the impact frame and holds a one-shot's last frame.


func _roof() -> NeonRoomDef:
	return ContentDB.get_def("neon_room", &"prison_roof") as NeonRoomDef


func test_sprite_sets_point_at_real_sheets() -> void:
	for set_id: StringName in [&"rydan", &"guard"]:
		var def := ContentDB.get_def("neon_sprite_set", set_id) as NeonSpriteSetDef
		check(def != null, "sprite set %s loads" % set_id)
		for state: StringName in [&"idle", &"walk", &"run", &"attack", &"cast", &"hurt", &"ko"]:
			var data: NeonSpriteState = def.get_state(state)
			check_eq(data.state, state, "%s has %s" % [set_id, state])
			check(ResourceLoader.exists(data.sheet), "%s sheet exists" % data.sheet)
		check(def.get_state(&"attack").impact > 0, "%s attack has an impact frame" % set_id)


func test_room_reads_its_shapes() -> void:
	var room: NeonRoomDef = _roof()
	check(room != null, "prison_roof loads")
	check(room.walk.size() >= 3, "walk outline is a polygon")
	check(IsoWalk.can_stand(room.spawn, room.walk, room.holes), "spawn is on the floor")
	for g: Dictionary in room.guards:
		for p: Vector2 in (g["path"] as PackedVector2Array):
			check(IsoWalk.can_stand(p, room.walk, room.holes), "guard path point %s is on the floor" % p)
	for i: Dictionary in room.interactables:
		check(IsoWalk.can_stand(i["pos"] as Vector2, room.walk, room.holes), "%s is reachable" % i["id"])


func test_dir_rows_round_trip() -> void:
	check_eq(IsoDir.row(Vector2.RIGHT), 0, "right is row 0")
	check_eq(IsoDir.row(Vector2.UP), 2, "up the screen is row 2")
	check_eq(IsoDir.row(Vector2.LEFT), 4, "left is row 4")
	check_eq(IsoDir.row(Vector2.DOWN), 6, "toward the camera is row 6")
	check_eq(IsoDir.row(Vector2(1, 1)), 7, "down-right is row 7")
	check_eq(IsoDir.row(Vector2.ZERO, 3), 3, "no direction keeps the fallback")
	for r: int in 8:
		check_eq(IsoDir.row(IsoDir.vector(r)), r, "row %d round trip" % r)


func test_walk_slides_and_blocks() -> void:
	var square := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	var hole := PackedVector2Array([Vector2(40, 40), Vector2(60, 40), Vector2(60, 60), Vector2(40, 60)])
	var holes: Array[PackedVector2Array] = [hole]
	check_eq(IsoWalk.step(Vector2(10, 10), Vector2(5, 5), square, holes), Vector2(15, 15), "free step")
	var slid: Vector2 = IsoWalk.step(Vector2(95, 50), Vector2(10, 4), square, holes)
	check(slid.x < 100.0 and slid.y > 50.0, "a step into the right wall slides down it")
	check(not IsoWalk.can_stand(Vector2(50, 50), square, holes), "a hole is not floor")
	check_eq(IsoWalk.velocity(Vector2(0, -2), 100.0), Vector2(0, -IsoWalk.Y_SQUASH * 100.0), "up is squashed")


func test_actor_impact_and_hold() -> void:
	var actor := IsoActor.new()
	actor.setup(&"rydan")
	var hits: Array[StringName] = []
	var ends: Array[StringName] = []
	actor.impact.connect(func(s: StringName) -> void: hits.append(s))
	actor.finished.connect(func(s: StringName) -> void: ends.append(s))
	actor.play(&"attack")
	actor.face(Vector2.LEFT)
	for i: int in 200:
		actor._process(1.0 / 60.0)
	check_eq(hits, [&"attack"] as Array[StringName], "attack lands once")
	check_eq(ends, [&"attack"] as Array[StringName], "attack ends once")
	check(not actor.is_playing_once(), "a finished one-shot holds")
	check_eq(actor.facing, 4, "faces left")
	actor.free()
