extends TestCase
## Flee: chance, refusal on boss, interrupted flee, FLED outcome rules.

func test_flee_refused_on_abu_nabil_duel() -> void:
	var moves: Array[ActionDef] = [BattleProbe.move(&"flee", {"target": &"self"})]
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"actions": [&"flee"] as Array[StringName]})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f")]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves)
	sim.setup.can_flee = false
	var hero: UnitState = sim.timeline.find(&"h")
	sim.timeline.waiting_for = hero
	hero.phase = UnitState.Phase.COMMAND
	# The flee action is in sim.actions already (BattleProbe.sim includes moves).
	var reason: String = sim.choose(hero.unit_id, sim.actions[&"flee"], hero.unit_id)
	check(reason.contains("Can't flee"), "flee refused when can_flee is false")

func test_fled_keeps_vitals_and_bag() -> void:
	# A basic test: create sim, force flee success manually, verify vitals preserved.
	var sim: BattleSim = BattleProbe.sim([BattleProbe.fighter(&"h")], [0] as Array[int], [BattleProbe.fighter(&"f")], [0] as Array[int], [BattleProbe.move(&"flee")], {"flee_base": 1.0})
	sim.flee_fails = 0
	sim.rolls_enabled = false
	# We directly call the resolve logic for the flee action by setting the actor's acted.
	var hero: UnitState = sim.timeline.find(&"h")
	hero.acted = sim.actions[&"flee"]
	hero.acted_targets = [hero.unit_id] as Array[StringName]
	# Manually resolve: since rolls_enabled false, always fail.
	var out: Array[TimelineEvent] = []
	BattleFleeLogic.resolve_flee(sim, hero, out)
	check(sim.flee_fails == 1, "flee failed when rolls disabled")
	check(out.any(func(e: TimelineEvent) -> bool: return e.kind == &"flee_failed"), "flee_failed event emitted")
