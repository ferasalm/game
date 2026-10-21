extends TestCase
## The rooftop's living rules: the sabil drink (save, refill, patrols return), beaten patrols and the grace time,
## the party's safe return and unstuck, the stall, the bench mesh, dialogue framing, and Bilqis never sticking.

const DT: float = 1.0 / 60.0
const SAVE_DIR: String = "user://test_b5_saves"


func _make() -> Rooftop:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	tree.root.add_child(rooftop)
	return rooftop


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _begin() -> void:
	GameState.start_new()
	Router.save_dir = SAVE_DIR


func _end() -> void:
	SaveService.new(SAVE_DIR).delete(SabilSpot.SAVE_SLOT)
	Router.save_dir = SaveService.DEFAULT_DIR
	GameState.reset()
	PaintedMaterials.use(null)


func test_drink_saves_refills_and_brings_the_patrols_back() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	GameState.set_vitals({&"zayd": {"hp": 3, "sp": 0}})
	GameState.cleared_patrols.append(&"patrol_pair")
	rooftop.reset_patrol()
	var pair: Patrol = _patrol(rooftop, &"patrol_pair")
	check(not pair.visible, "a beaten patrol is gone")
	check(rooftop.sabil.drink(), "the drink succeeds")
	check(GameState.vitals.is_empty(), "everyone is refilled (no carried vitals = full)")
	check(GameState.cleared_patrols.is_empty(), "no patrol stays beaten")
	check_eq(GameState.save_point, &"sabil", "the sabil is the save point")
	check(Router.has_save(SabilSpot.SAVE_SLOT), "the game was saved")
	check(pair.visible and not pair.is_cleared(), "the patrol is back")
	check_eq(pair.position, pair.lane()[0], "at its lane start")
	var saved: Dictionary = SaveService.new(SAVE_DIR).read(SabilSpot.SAVE_SLOT)
	check((saved["cleared_patrols"] as Array).is_empty() and (saved["vitals"] as Dictionary).is_empty(), "the save holds the refilled state")
	rooftop.free()
	_end()


func test_a_failed_save_changes_nothing() -> void:
	_begin()
	GameState.set_vitals({&"zayd": {"hp": 3, "sp": 0}})
	GameState.cleared_patrols.append(&"patrol_pair")
	var problem: String = SabilDrink.apply(&"sabil", 1, func(_slot: int) -> String: return "disk full")
	check(not problem.is_empty(), "the save failed")
	check_eq(Vitals.hp_of(GameState.vitals, &"zayd", 999), 3, "vitals as before")
	check_eq(GameState.cleared_patrols, [&"patrol_pair"] as Array[StringName], "patrols as before")
	check_eq(GameState.save_point, &"", "save point as before")
	_end()


func _patrol(rooftop: Rooftop, encounter: StringName) -> Patrol:
	for p: Patrol in rooftop.patrols:
		if p.encounter_id == encounter:
			return p
	return null


func test_beaten_patrols_stay_gone_after_a_battle_and_others_keep_walking() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	var pair: Patrol = _patrol(rooftop, &"patrol_pair")
	var drone: Patrol = _patrol(rooftop, &"patrol_drone")
	drone.position += Vector3(1.0, 0.0, 0.0)
	var kept: Vector3 = drone.position
	GameState.cleared_patrols.append(&"patrol_pair")
	rooftop.reset_patrol()
	check(not pair.visible and pair.is_cleared(), "the beaten patrol is gone")
	check_eq(drone.position, kept, "the others keep their places")
	check(drone.visible, "and stay in play")
	rooftop.free()
	_end()


func test_the_patrol_that_fought_restarts_and_nobody_touches_for_the_grace_time() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	var hits: Array = []
	rooftop.encounter_touched.connect(func(id: StringName, _b: bool) -> void: hits.append(id))
	var drone: Patrol = _patrol(rooftop, &"patrol_drone")
	drone.position = rooftop.player.position + Vector3(0.3, 0.0, 0.0)
	drone._physics_process(DT)
	check_eq(hits.size(), 1, "the touch fired")
	rooftop.set_exploring(false)
	rooftop.set_exploring(true)
	rooftop.reset_patrol()
	check_eq(drone.position, drone.lane()[0], "the patrol that fought is back at its lane start")
	for p: Patrol in rooftop.patrols:
		p.position = rooftop.player.position
		p._physics_process(_rules().touch_grace - 0.5)
	check_eq(hits.size(), 1, "no touch inside the grace time")
	rooftop.free()
	_end()


func test_the_party_is_put_clear_of_a_patrol_after_a_battle() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	var lane: PackedVector3Array = rooftop.patrol.lane()
	rooftop.player.position = Vector3(lane[0].x, lane[0].y, lane[0].z + 1.0)
	rooftop.reset_patrol()
	var lanes: Array[PackedVector3Array] = []
	for p: Patrol in rooftop.patrols:
		lanes.append(p.lane())
	check(PatrolSafety.nearest_lane_distance(rooftop.player.position, lanes) >= _rules().safe_return_distance,
		"the party stands at least safe_return_distance from every patrol lane")
	rooftop.free()
	_end()


func test_unstuck_goes_to_a_clear_place() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	rooftop.player.position = Vector3(1.5, rooftop.player.position.y, 15.5)
	var target: Vector3 = rooftop.last_safe_position()
	var lanes: Array[PackedVector3Array] = []
	for p: Patrol in rooftop.patrols:
		lanes.append(p.lane())
	check(PatrolSafety.nearest_lane_distance(target, lanes) >= _rules().unstuck_patrol_distance, "3 m or more from every patrol")
	rooftop.teleport_party(target)
	check(rooftop.player.position.distance_to(target) < 0.01, "the party is there")
	rooftop.free()
	_end()


func test_the_stall_opens_the_shop_and_the_prompt_is_a_pill() -> void:
	_begin()
	var rooftop: Rooftop = _make()
	var shops: Array[StringName] = []
	rooftop.stall.opened.connect(func(id: StringName) -> void: shops.append(id))
	rooftop.stall._physics_process(DT)
	check(not rooftop.stall.pill().visible, "no pill far from the stall")
	rooftop.player.position = rooftop.stall.position + Vector3(0.5, 0.0, 0.0)
	rooftop.stall._physics_process(DT)
	check(rooftop.stall.pill().visible, "the pill shows at the counter")
	check_eq(rooftop.stall.pill().verb_text(), "Talk", "its verb comes from the localization key")
	rooftop.stall._interact()
	check_eq(shops, [&"herb_stall"] as Array[StringName], "interact opens the herb stall's shop")
	check(Screens.is_open_id(&"shop"), "the shop screen is up")
	Screens.clear()
	rooftop.free()
	_end()
