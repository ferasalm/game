extends TestCase
## BattleSim: unit ids, determinism (T1), every battle ends (T2), refused choices, event order, stall guard.

const RANK: Dictionary[StringName, int] = {
	&"dodged": 1, &"crit": 1, &"damage": 1, &"interrupted": 1, &"knocked_back": 1, &"status": 3,
	&"resisted": 3, &"status_ended": 4, &"down": 5, &"fizzled": 1, &"flee_failed": 1, &"fled": 6,
	&"victory": 6, &"defeat": 6,
}

var _loader: BattleLoader


func _load() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	check_eq(db.call("load_all"), PackedStringArray(), "shipped content loads")
	_loader = BattleLoader.from_db(db)
	db.free()


func test_unit_ids_and_slots() -> void:
	_load()
	var sim: BattleSim = _loader.make_sim(&"swift_hilt", &"keen_blade", 1)
	var ids: PackedStringArray = []
	for unit: UnitState in sim.timeline.units:
		ids.append("%s/%d/%d" % [unit.unit_id, unit.side, unit.slot])
	check_eq(",".join(ids), "zayd/0/0,bilqis/0/2,concession_enforcer_1/1/0,concession_enforcer_2/1/1,survey_drone_1/1/2",
		"party use def ids, enemies count from 1, slots follow the encounter")


func test_same_seed_same_choices_same_events() -> void:
	_load()
	var a: String = BattleProbe.text(BattleLoader.autoplay(_loader.make_sim(&"anvil_hilt", &"broad_blade", 7)))
	var b: String = BattleProbe.text(BattleLoader.autoplay(_loader.make_sim(&"anvil_hilt", &"broad_blade", 7)))
	var c: String = BattleProbe.text(BattleLoader.autoplay(_loader.make_sim(&"anvil_hilt", &"broad_blade", 8)))
	check(a.length() > 100, "a real battle happened")
	check_eq(a, b, "T1: same seed, same events")
	check(a != c, "another seed plays out differently")


func test_every_battle_ends_for_every_pairing() -> void:
	_load()
	for hilt_id: StringName in _loader.hilts:
		for blade_id: StringName in _loader.blades:
			var stalled: int = 0
			for battle_seed: int in range(1, 31):
				var sim: BattleSim = _loader.make_sim(hilt_id, blade_id, battle_seed)
				BattleLoader.autoplay(sim)
				var ended: bool = sim.result == &"victory" or sim.result == &"defeat"
				if not ended or sim.ticks >= sim.rules.max_ticks:
					stalled += 1
			check_eq(stalled, 0, "T2: %s + %s: battles that stalled" % [hilt_id, blade_id])


func test_choose_refusals() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"max_sp": 2,
		"actions": [&"hit", &"big"] as Array[StringName]})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"agility": 1}), BattleProbe.fighter(&"g", {"agility": 1})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit"), BattleProbe.move(&"big", {"sp_cost": 5}),
		BattleProbe.move(&"other")]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0, 2] as Array[int], moves)
	check_eq(sim.choose(&"h", moves[0], &"f_1"), "not waiting for 'h'", "nobody waits yet")
	BattleProbe.play_until(sim, &"command", Callable())
	var hero: UnitState = sim.waiting_hero()
	check(hero != null and hero.unit_id == &"h", "the hero waits at COMMAND")
	check_eq(sim.choices_for(hero).size(), 1, "the 5 SP move is not affordable with 2 SP")
	check(sim.choose(&"h", moves[1], &"f_1").contains("not enough SP"), "unaffordable move refused")
	check(sim.choose(&"h", moves[2], &"f_1").contains("not a move"), "a move the unit lacks is refused")
	check(sim.choose(&"h", moves[0], &"g_1").contains("not a valid target"), "covered target refused")
	check_eq(sim.choose(&"h", moves[0], &"f_1"), "", "a legal choice is accepted")
	check(sim.waiting_hero() == null, "no one waits after the choice")


func test_events_follow_the_documented_order() -> void:
	_load()
	for battle_seed: int in range(1, 11):
		var sim: BattleSim = _loader.make_sim(&"swift_hilt", &"broad_blade", battle_seed)
		var last_rank: int = 0
		for event: TimelineEvent in BattleLoader.autoplay(sim):
			if event.kind == &"command" or event.kind == &"act":
				last_rank = 0
				continue
			var rank: int = RANK[event.kind]
			check(rank >= last_rank, "seed %d: %s came after a later kind" % [battle_seed, event.kind])
			last_rank = rank
		check(sim.result == &"victory" or sim.result == &"defeat", "seed %d ended" % battle_seed)


func test_stall_guard_ends_the_battle_as_defeat() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"agility": 1})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"agility": 1})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit")]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves, {"max_ticks": 150})
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"never", Callable())
	check_eq(sim.result, &"defeat", "the stall guard defeats the party")
	check_eq(sim.ticks, 150, "at max_ticks")
	check_eq(BattleProbe.count(trace, &"defeat"), 1, "one defeat event")
	check_eq(sim.step().size(), 0, "a finished battle stays finished")
