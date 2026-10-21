extends TestCase
## Tech moves: ally / self / all-target moves, heals (never above max HP, downed allies stay down unless the move
## revives), the guarded and overclocked statuses, and the damage-taken multiplier.


func _guarded() -> StatusDef:
	var status := StatusDef.new()
	status.id = &"guarded"
	status.turns = 2
	status.damage_taken = 0.6
	return status


func _moves() -> Array[ActionDef]:
	return [
		BattleProbe.move(&"hit", {"power": 20, "is_melee": false}),
		BattleProbe.move(&"mend", {"power": 0, "target": &"ally", "heal": 30, "is_melee": false}),
		BattleProbe.move(&"raise", {"power": 0, "target": &"ally", "heal": 25, "revive": true}),
		BattleProbe.move(&"guard", {"power": 0, "target": &"self", "applies_status": &"guarded"}),
		BattleProbe.move(&"arc", {"power": 10, "target": &"all_foes", "is_melee": false}),
		BattleProbe.move(&"rally", {"power": 0, "target": &"all_allies", "applies_status": &"guarded"}),
	]


## Hero h (all moves) and ally a (HP 100) in the party, foes f1 and f2 (HP 100, defense 10).
func _duo(rule_props: Dictionary = {}) -> BattleSim:
	var hero := BattleProbe.fighter(&"h", {"attack": 10})
	hero.actions = [&"hit", &"mend", &"raise", &"guard", &"arc", &"rally"] as Array[StringName]
	var ally := BattleProbe.fighter(&"a", {"max_hp": 100})
	var foe := BattleProbe.fighter(&"f", {"max_hp": 100, "attack": 20, "defense": 10})
	var heroes: Array[CombatantDef] = [hero, ally]
	var foes: Array[CombatantDef] = [foe, foe]
	var statuses: Array[StatusDef] = [_guarded()]
	return BattleProbe.sim(
		heroes, [0, 1] as Array[int], foes, [0, 1] as Array[int], _moves(), rule_props, statuses)


func _act(sim: BattleSim, actor_id: StringName, action_id: StringName, target_id: StringName) -> Array[TimelineEvent]:
	var actor: UnitState = sim.timeline.find(actor_id)
	actor.acted = sim.actions[action_id]
	actor.acted_targets = [target_id] as Array[StringName] if target_id != &"" else ([] as Array[StringName])
	return sim._resolver.resolve(actor)


func test_heal_restores_hp_plus_attack_share_and_never_exceeds_max() -> void:
	var sim: BattleSim = _duo({"heal_attack_factor": 0.5})
	var ally: UnitState = sim.timeline.find(&"a")
	ally.hp = 40
	var events: Array[TimelineEvent] = _act(sim, &"h", &"mend", &"a")
	check_eq(ally.hp, 75, "40 + 30 + attack 10 x 0.5")
	var healed: TimelineEvent = BattleProbe.first(events, &"healed")
	check(healed != null and healed.unit_id == &"a" and healed.value == 35, "healed event carries the amount restored")
	ally.hp = 90
	events = _act(sim, &"h", &"mend", &"a")
	check_eq(ally.hp, 100, "capped at max HP")
	check_eq(BattleProbe.first(events, &"healed").value, 10, "and the event says only 10 was restored")


func test_a_downed_ally_stays_down_without_revive() -> void:
	var sim: BattleSim = _duo()
	var ally: UnitState = sim.timeline.find(&"a")
	ally.hp = 0
	var hero: UnitState = sim.timeline.find(&"h")
	var ids: Array[StringName] = []
	for target: UnitState in sim.valid_targets(hero, sim.actions[&"mend"]):
		ids.append(target.unit_id)
	check(not ids.has(&"a"), "a heal cannot target a downed ally")
	_act(sim, &"h", &"mend", &"a")
	check_eq(ally.hp, 0, "even when forced through the resolver it retargets and the ally stays down")
	check(not ally.is_alive(), "still down")


func test_revive_stands_a_downed_ally_up_on_the_track() -> void:
	var sim: BattleSim = _duo()
	var ally: UnitState = sim.timeline.find(&"a")
	ally.hp = 0
	ally.pos = 9000
	var hero: UnitState = sim.timeline.find(&"h")
	check(sim.valid_targets(hero, sim.actions[&"raise"]).has(ally), "a revive move may target a downed ally")
	var events: Array[TimelineEvent] = _act(sim, &"h", &"raise", &"a")
	check(ally.is_alive() and ally.hp == 25, "back up with the move's heal (factor 0 in the probe rules)")
	check_eq(ally.pos, Timeline.AFTER_ACT_POS, "placed on the track again")
	check_eq(ally.phase, UnitState.Phase.WAIT, "waiting, not casting")
	check(BattleProbe.first(events, &"revived") != null, "a revived event")


func test_self_move_needs_no_target_and_keeps_its_full_turns() -> void:
	var sim: BattleSim = _duo()
	var hero: UnitState = sim.timeline.find(&"h")
	sim.timeline.waiting_for = hero
	hero.phase = UnitState.Phase.COMMAND
	check_eq(sim.choose(&"h", sim.actions[&"guard"], &""), "", "self move chosen with no target")
	check_eq(hero.targets, [&"h"] as Array[StringName], "its target is the actor")
	_act(sim, &"h", &"guard", &"")
	check_eq(hero.status_turns[&"guarded"], 2, "a status the actor gave itself does not lose a turn at once")
	_act(sim, &"h", &"hit", &"f_1")
	check_eq(hero.status_turns[&"guarded"], 1, "it loses one on the next act")


func test_guarded_cuts_damage_taken() -> void:
	var sim: BattleSim = _duo()
	var plain: int = BattleProbe.first(_act(sim, &"f_1", &"hit", &"a"), &"damage").value
	sim.timeline.find(&"a").apply_status(_guarded())
	var guarded: int = BattleProbe.first(_act(sim, &"f_1", &"hit", &"a"), &"damage").value
	check_eq(plain, 35, "20 power + 20 attack - 10 x 0.5 defense")
	check_eq(guarded, roundi(35 * 0.6), "guarded: x0.6")


func test_all_foes_move_resolves_once_per_living_target() -> void:
	var sim: BattleSim = _duo()
	var events: Array[TimelineEvent] = _act(sim, &"h", &"arc", &"")
	check_eq(BattleProbe.count(events, &"damage"), 2, "both foes hit once")
	check_eq(sim.timeline.find(&"f_1").hp, 100 - (10 + 10 - 5), "damage 15 each")
	check_eq(sim.timeline.find(&"f_2").hp, 85, "second foe too")
	sim.timeline.find(&"f_2").hp = 0
	events = _act(sim, &"h", &"arc", &"")
	check_eq(BattleProbe.count(events, &"damage"), 1, "a downed foe is skipped")


func test_all_allies_move_reaches_every_living_ally() -> void:
	var sim: BattleSim = _duo()
	var events: Array[TimelineEvent] = _act(sim, &"h", &"rally", &"")
	check_eq(BattleProbe.count(events, &"status"), 2, "both heroes get the status")
	sim.timeline.find(&"a").hp = 0
	events = _act(sim, &"h", &"rally", &"")
	check_eq(BattleProbe.count(events, &"status"), 1, "a downed ally is skipped")


func test_target_choice_rules() -> void:
	var sim: BattleSim = _duo()
	var hero: UnitState = sim.timeline.find(&"h")
	sim.timeline.waiting_for = hero
	hero.phase = UnitState.Phase.COMMAND
	check(sim.choose(&"h", sim.actions[&"mend"], &"f_1") != "", "an ally move cannot pick a foe")
	check(sim.choose(&"h", sim.actions[&"hit"], &"a") != "", "a foe move cannot pick an ally")
	check(sim.choose(&"h", sim.actions[&"hit"], &"") != "", "a foe move needs a target")
	check_eq(sim.choose(&"h", sim.actions[&"arc"], &""), "", "an all-foes move needs none")
	check_eq(hero.targets.size(), 2, "and is aimed at both foes")


func test_damage_taken_multiplier_multiplies_statuses() -> void:
	var unit := UnitState.create(BattleProbe.fighter(&"u"), &"u", 0, 0)
	check_eq(unit.damage_taken_mult(), 1.0, "no status")
	unit.apply_status(_guarded())
	check_eq(unit.damage_taken_mult(), 0.6, "guarded")
