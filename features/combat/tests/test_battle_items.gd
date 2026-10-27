extends TestCase
## The Items command in the sim: a herb is reserved when chosen (two heroes cannot share the last one), cast at its
## cast speed, consumed at ACT with the real amounts, and refunded when the target is no longer valid, when the cast
## is cut, or when the user falls first.


func _sim(bag: Dictionary) -> BattleSim:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var party: Array[CombatantDef] = [loader.rydan_with(&"swift_hilt", &"keen_blade"), loader.fighter(&"bilqis", &"", &"", &"")]
	var setup: BattleSetup = loader.make_setup(party, 7, 0)
	setup.bag = bag
	var sim: BattleSim = BattleSim.create_from(setup)
	for unit: UnitState in sim.timeline.units:
		if unit.side == 1:
			unit.pos = 0
	return sim


## Rydan waits for a command first, Bilqis a tick later.
func _two_waiting(sim: BattleSim) -> void:
	sim.timeline.find(&"rydan").pos = Timeline.COMMAND_POINT - 1
	sim.timeline.find(&"bilqis").pos = Timeline.COMMAND_POINT - 2
	sim.step()


## Only Rydan waits; Bilqis stays at the start of the track so the cast can run to ACT (time stops while a hero waits).
func _one_waiting(sim: BattleSim) -> void:
	sim.timeline.find(&"rydan").pos = Timeline.COMMAND_POINT - 1
	sim.timeline.find(&"bilqis").pos = 0
	sim.step()


func _until(sim: BattleSim, kind: StringName, frames: int = 600) -> Array[TimelineEvent]:
	var seen: Array[TimelineEvent] = []
	for i: int in frames:
		for event: TimelineEvent in sim.step():
			seen.append(event)
			if event.kind == kind:
				return seen
	return seen


func _kinds(events: Array[TimelineEvent]) -> Array[StringName]:
	var out: Array[StringName] = []
	for event: TimelineEvent in events:
		out.append(event.kind)
	return out


func test_a_herb_is_reserved_and_cast_at_its_speed() -> void:
	var sim: BattleSim = _sim({&"pink_herb": 1})
	_two_waiting(sim)
	var rydan: UnitState = sim.timeline.find(&"rydan")
	check_eq(sim.choose_item(&"rydan", &"pink_herb", &"rydan"), "", "Rydan takes the herb")
	check_eq(sim.bag.reserved(&"pink_herb"), 1, "one is reserved")
	check_eq(sim.bag.count(&"pink_herb"), 1, "the bag still holds it until ACT")
	check(rydan.action is ItemAction and rydan.phase == UnitState.Phase.CAST, "a cast is on the timeline")
	var def := ContentDB.get_def("consumable", &"pink_herb") as ConsumableDef
	check_eq(rydan.action.cast_speed, def.cast_speed, "at the herb's cast speed")
	check_eq(rydan.action.recovery, def.recovery, "and recovery")


func test_two_heroes_cannot_claim_the_last_herb() -> void:
	var sim: BattleSim = _sim({&"pink_herb": 1})
	_two_waiting(sim)
	check_eq(sim.choose_item(&"rydan", &"pink_herb", &"rydan"), "", "the first claim works")
	sim.step()
	check(sim.waiting_hero() != null and sim.waiting_hero().unit_id == &"bilqis", "Bilqis is next")
	check(sim.choose_item(&"bilqis", &"pink_herb", &"bilqis") != "", "the second claim is refused")
	check_eq(sim.bag.available(&"pink_herb"), 0, "none is available")
	check_eq(sim.items.claims(), 1, "one claim is open")


func test_it_is_consumed_at_act_with_the_real_amount() -> void:
	var sim: BattleSim = _sim({&"pink_herb": 1})
	_one_waiting(sim)
	var rydan: UnitState = sim.timeline.find(&"rydan")
	rydan.hp = rydan.def.max_hp - 50
	sim.choose_item(&"rydan", &"pink_herb", &"rydan")
	var events: Array[TimelineEvent] = _until(sim, &"healed")
	var healed: TimelineEvent = events[-1]
	check_eq(healed.value, 50, "heals only what is missing (the herb gives 120)")
	check(_kinds(events).has(&"item_used"), "item_used comes first")
	check_eq(rydan.hp, rydan.def.max_hp, "HP is full")
	check_eq(sim.bag.count(&"pink_herb"), 0, "the herb is used up")
	check_eq(sim.bag.reserved(&"pink_herb"), 0, "and the claim is gone")


func test_yellow_herb_restores_sp() -> void:
	var sim: BattleSim = _sim({&"yellow_herb": 1})
	_one_waiting(sim)
	var bilqis: UnitState = sim.timeline.find(&"bilqis")
	bilqis.sp = 1
	check_eq(sim.choose_item(&"rydan", &"yellow_herb", &"bilqis"), "", "Rydan gives Bilqis the herb")
	var events: Array[TimelineEvent] = _until(sim, &"sp_restored")
	check_eq(events[-1].value, 12, "12 SP come back")
	check_eq(bilqis.sp, 13, "SP rises by the real amount")


func test_target_invalid_at_act_fizzles_and_refunds() -> void:
	var sim: BattleSim = _sim({&"white_herb": 1})
	_one_waiting(sim)
	var bilqis: UnitState = sim.timeline.find(&"bilqis")
	bilqis.hp = 0
	check(sim.choose_item(&"rydan", &"pink_herb", &"bilqis") != "", "a living-only herb on a downed hero is refused")
	check_eq(sim.choose_item(&"rydan", &"white_herb", &"bilqis"), "", "the white herb can pick the downed hero")
	bilqis.hp = 30  # she stood up some other way before the cast landed
	var events: Array[TimelineEvent] = _until(sim, &"fizzled")
	check(_kinds(events).has(&"fizzled"), "the herb fizzles")
	check_eq(sim.bag.count(&"white_herb"), 1, "nothing was lost")
	check_eq(sim.bag.reserved(&"white_herb"), 0, "and the claim is released")
	check_eq(bilqis.hp, 30, "she was not healed")


func test_white_herb_revives_a_downed_hero() -> void:
	var sim: BattleSim = _sim({&"white_herb": 1})
	_one_waiting(sim)
	var bilqis: UnitState = sim.timeline.find(&"bilqis")
	bilqis.hp = 0
	sim.choose_item(&"rydan", &"white_herb", &"bilqis")
	var events: Array[TimelineEvent] = _until(sim, &"healed")
	check(_kinds(events).has(&"revived"), "revived is announced")
	check(bilqis.is_alive() and bilqis.hp == roundi(bilqis.def.max_hp * 0.3), "back up with 30% HP")
	check_eq(sim.bag.count(&"white_herb"), 0, "the herb is spent")


func test_party_herb_heals_the_living_only_and_fizzles_when_nobody_gains() -> void:
	var sim: BattleSim = _sim({&"qishr_cup": 2})
	_one_waiting(sim)
	var rydan: UnitState = sim.timeline.find(&"rydan")
	var bilqis: UnitState = sim.timeline.find(&"bilqis")
	rydan.hp = rydan.def.max_hp - 20
	bilqis.hp = 0
	check_eq(sim.choose_item(&"rydan", &"qishr_cup", &""), "", "the cup needs no target")
	var events: Array[TimelineEvent] = _until(sim, &"healed")
	check_eq(events[-1].unit_id, &"rydan", "the living hero heals")
	check_eq(bilqis.hp, 0, "the downed one is left alone")
	var full: BattleSim = _sim({&"qishr_cup": 1})
	_one_waiting(full)
	full.choose_item(&"rydan", &"qishr_cup", &"")
	check(_kinds(_until(full, &"fizzled")).has(&"fizzled"), "with everyone full it fizzles")
	check_eq(full.bag.count(&"qishr_cup"), 1, "and refunds")


func test_the_user_falling_before_act_refunds() -> void:
	var sim: BattleSim = _sim({&"pink_herb": 1})
	_two_waiting(sim)
	sim.choose_item(&"rydan", &"pink_herb", &"rydan")
	var rydan: UnitState = sim.timeline.find(&"rydan")
	rydan.hp = 0
	var gone: Array[TimelineEvent] = []
	sim._resolver._bring_down(rydan, gone)  # what a killing blow does: the cast is cleared
	sim.step()
	check_eq(sim.bag.available(&"pink_herb"), 1, "the herb is available again")
	check_eq(sim.bag.count(&"pink_herb"), 1, "and still in the bag")
	check_eq(sim.items.claims(), 0, "no claim is left")


func test_a_cut_cast_refunds() -> void:
	var sim: BattleSim = _sim({&"pink_herb": 1})
	_two_waiting(sim)
	sim.choose_item(&"rydan", &"pink_herb", &"rydan")
	var cutter := ActionDef.new()
	cutter.cancels_cast = true
	var event: TimelineEvent = sim.timeline.hit(&"rydan", cutter)
	check_eq(event.kind, &"interrupted", "the cast was interrupted")
	sim.step()
	check_eq(sim.bag.available(&"pink_herb"), 1, "the herb stays in the bag")


func test_ko_ally_herb_lists_only_the_downed_and_the_picker_refuses_the_rest() -> void:
	var sim: BattleSim = _sim({&"white_herb": 1, &"pink_herb": 1})
	_two_waiting(sim)
	var white: ConsumableDef = sim.items.consumable(&"white_herb")
	check(sim.items.valid_targets(sim.timeline.find(&"rydan"), white).is_empty(), "nobody is downed: no targets")
	sim.timeline.find(&"bilqis").hp = 0
	check_eq(sim.items.valid_targets(sim.timeline.find(&"rydan"), white).size(), 1, "the downed hero is the only target")
	check_eq(sim.items.listed().size(), 2, "both herbs are listed")
	check(sim.items.any_available(), "something can be used")
