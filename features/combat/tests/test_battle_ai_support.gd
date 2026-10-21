extends TestCase
## BattleAI with support moves: heal an ally under 40% HP, revive the fallen, guard before a big enemy cast, and
## never waste a heal or buff when nobody needs it.


func _status(id: StringName, props: Dictionary) -> StatusDef:
	var status := StatusDef.new()
	status.id = id
	status.turns = 2
	for key: Variant in props:
		status.set(key as String, props[key])
	return status


## Hero h (hit, mend, raise, guard) with ally a, against foe f (hit; a big beam is set by the tests).
func _sim() -> BattleSim:
	var hero := BattleProbe.fighter(&"h")
	hero.actions = [&"hit", &"mend", &"raise", &"guard"] as Array[StringName]
	var ally := BattleProbe.fighter(&"a")
	var foe := BattleProbe.fighter(&"f")
	var moves: Array[ActionDef] = [
		BattleProbe.move(&"hit", {"power": 10}),
		BattleProbe.move(&"mend", {"power": 0, "target": &"ally", "heal": 30}),
		BattleProbe.move(&"raise", {"power": 0, "target": &"ally", "heal": 20, "revive": true}),
		BattleProbe.move(&"guard", {"power": 0, "target": &"self", "applies_status": &"guarded"}),
		BattleProbe.move(&"beam", {"power": 40})]
	var statuses: Array[StatusDef] = [_status(&"guarded", {"damage_taken": 0.6})]
	var sim: BattleSim = BattleProbe.sim(
		[hero, ally] as Array[CombatantDef], [0, 1] as Array[int], [foe] as Array[CombatantDef], [0] as Array[int],
		moves, {"ai_heal_below": 0.4, "ai_big_cast_power": 25}, statuses)
	var unit: UnitState = sim.timeline.find(&"h")
	unit.phase = UnitState.Phase.COMMAND
	sim.timeline.waiting_for = unit
	return sim


func _pick(sim: BattleSim) -> BattleAI.Choice:
	return BattleAI.pick(sim, sim.timeline.find(&"h"))


func _cast_beam(sim: BattleSim) -> void:
	var foe: UnitState = sim.timeline.find(&"f_1")
	foe.phase = UnitState.Phase.CAST
	foe.action = sim.actions[&"beam"]


func test_heals_the_weakest_ally_under_the_threshold() -> void:
	var sim: BattleSim = _sim()
	sim.timeline.find(&"a").hp = 39
	var choice: BattleAI.Choice = _pick(sim)
	check(choice.action.id == &"mend" and choice.target_id == &"a", "mend the ally at 39%")
	sim.timeline.find(&"h").hp = 20
	choice = _pick(sim)
	check_eq(choice.target_id, &"h", "the hero at 20% is weaker still, so he is mended first")


func test_the_heal_rule_ignores_an_ally_at_or_above_the_threshold() -> void:
	var sim: BattleSim = _sim()
	var hero: UnitState = sim.timeline.find(&"h")
	var moves: Array[ActionDef] = BattleTargets.affordable_moves(hero, sim.actions)
	sim.timeline.find(&"a").hp = 40
	check(BattleAI._heal_choice(sim, moves, hero) == null, "40% is not under the 40% threshold")
	sim.timeline.find(&"a").hp = 39
	check(BattleAI._heal_choice(sim, moves, hero) != null, "39% is")


func test_never_picks_heal_when_everyone_is_at_full_hp() -> void:
	for seed_value: int in 30:
		var sim: BattleSim = _sim()
		sim.rng.seed = seed_value
		var id: StringName = _pick(sim).action.id
		check(id == &"hit", "only the attack is useful at full HP, got %s (seed %d)" % [id, seed_value])


func test_revives_a_fallen_ally_before_healing() -> void:
	var sim: BattleSim = _sim()
	sim.timeline.find(&"a").hp = 0
	var choice: BattleAI.Choice = _pick(sim)
	check(choice.action.id == &"raise" and choice.target_id == &"a", "stand the fallen ally up")


func test_guards_before_a_big_enemy_cast_but_not_a_small_one() -> void:
	var sim: BattleSim = _sim()
	_cast_beam(sim)
	var choice: BattleAI.Choice = _pick(sim)
	check_eq(choice.action.id, &"guard", "power 40 >= 25: guard")
	sim.timeline.find(&"h").apply_status(_status(&"guarded", {"damage_taken": 0.6}))
	check(_pick(sim).action.id != &"guard", "already guarded: do something else")
	var small: BattleSim = _sim()
	small.timeline.find(&"f_1").phase = UnitState.Phase.CAST
	small.timeline.find(&"f_1").action = small.actions[&"hit"]
	check(_pick(small).action.id != &"guard", "power 10 is not a big cast")


func test_guard_is_never_a_random_pick() -> void:
	for seed_value: int in 30:
		var sim: BattleSim = _sim()
		sim.rng.seed = seed_value
		check(_pick(sim).action.id != &"guard", "no big cast, no guard (seed %d)" % seed_value)


func test_cancel_still_comes_first() -> void:
	var sim: BattleSim = _sim()
	sim.actions[&"hit"].cancels_cast = true
	_cast_beam(sim)
	sim.timeline.find(&"a").hp = 10
	check_eq(_pick(sim).action.id, &"hit", "cancelling the beam beats healing and guarding")
