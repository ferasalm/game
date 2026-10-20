extends TestCase
## The reverse stab: only when the party was ambushed, Zayd strikes the lowest-slot living enemy first.


func _ambush_sim(ambush: int, foe_hp: int = 400) -> BattleSim:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"zayd", {"attack": 20, "knockback_bonus": 1000})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"max_hp": foe_hp, "defense": 14}),
		BattleProbe.fighter(&"g", {"max_hp": foe_hp, "defense": 14})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit"),
		BattleProbe.move(&"reverse_stab", {"power": 24, "knockback": 3000, "recovery": 0})]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [2, 1] as Array[int], moves, {},
		[] as Array[StatusDef], ambush)
	for unit: UnitState in sim.timeline.units:
		unit.pos = 6000
	return sim


func test_stab_hits_the_lowest_slot_enemy_first() -> void:
	var sim: BattleSim = _ambush_sim(1)
	var events: Array[TimelineEvent] = sim.opening()
	# (24 + 20 - 7) * 1.15 = 42.55 -> 43; knockback 3000 + 1000 bonus from 6000
	check_eq(BattleProbe.text(events), "reverse_stab:zayd:0,damage:g_1:43,knocked_back:g_1:2000",
		"g_1 stands in slot 1, the lowest living slot")
	check_eq(sim.timeline.find(&"g_1").hp, 357, "hp")
	check_eq(sim.timeline.find(&"f_1").hp, 400, "the other enemy is untouched")
	check_eq(sim.opening().size(), 0, "only once")


func test_stab_happens_only_with_an_ambush() -> void:
	for ambush: int in [0, 2]:
		var sim: BattleSim = _ambush_sim(ambush)
		check_eq(sim.opening().size(), 0, "ambush %d: no stab" % ambush)
		var first: Array[TimelineEvent] = sim.step()
		check_eq(BattleProbe.count(first, &"reverse_stab"), 0, "ambush %d: step() adds none" % ambush)


func test_step_plays_the_stab_first_if_the_view_did_not() -> void:
	var sim: BattleSim = _ambush_sim(1)
	var first: Array[TimelineEvent] = sim.step()
	check_eq(first[0].kind, &"reverse_stab", "first event of the battle")
	check_eq(sim.opening().size(), 0, "and not repeated")
	check_eq(BattleProbe.count(sim.step(), &"reverse_stab"), 0, "nor on the next step")


func test_stab_can_down_an_enemy_and_is_deterministic() -> void:
	var sim: BattleSim = _ambush_sim(1, 10)
	var events: Array[TimelineEvent] = sim.opening()
	check_eq(BattleProbe.text(events), "reverse_stab:zayd:0,damage:g_1:43,down:g_1:0", "a kill: no knockback, then down")
	check_eq(sim.timeline.find(&"g_1").hp, 0, "dead")
	var again: Array[TimelineEvent] = _ambush_sim(1, 10).opening()
	check_eq(BattleProbe.text(again), BattleProbe.text(events), "same seed, same stab")


func test_no_stab_without_zayd() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"bilqis")]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f")]
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit"), BattleProbe.move(&"reverse_stab")]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves, {},
		[] as Array[StatusDef], 1)
	check_eq(sim.opening().size(), 0, "no zayd in the party")
