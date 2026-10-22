class_name TestAbuNabilCombat
extends TestCase
## Abu Nabil combat rules: miss rolls for confused units, status cures, uses per battle, and boss AI policy.


func _status(status_id: StringName, miss_chance: float = 0.5, turns: int = 2) -> StatusDef:
	var s := StatusDef.new()
	s.id = status_id
	s.name_key = "STATUS_" + String(status_id).to_upper()
	s.miss_chance = miss_chance
	s.turns = turns
	return s


func test_miss_rate_over_200_seeds_and_miss_effects() -> void:
	var confused := _status(&"confused", 0.5, 2)
	var move := BattleProbe.move(&"strike", {"power": 12, "knockback": 800, "cancels_cast": true})
	var friendly := BattleProbe.move(&"mend", {"power": 0, "target": &"self", "heal": 20})
	var miss_count: int = 0
	for seed_val: int in range(1, 201):
		var hero := BattleProbe.fighter(&"h", {"actions": [&"strike"] as Array[StringName]})
		var foe := BattleProbe.fighter(&"f", {"agility": 1})
		var sim: BattleSim = BattleProbe.sim([hero], [0], [foe], [0], [move, friendly], {}, [confused])
		sim.rng.seed = seed_val
		var h: UnitState = sim.timeline.find(&"h")
		h.apply_status(confused)
		h.sp = 0
		h.phase = UnitState.Phase.COMMAND
		sim.timeline.waiting_for = h
		sim.choose(&"h", move, &"f_1")
		var foe_unit: UnitState = sim.timeline.find(&"f_1")
		foe_unit.phase = UnitState.Phase.CAST
		foe_unit.action = move
		# Move to just before ACT so the next tick resolves the act
		h.pos = Timeline.ACT_POINT - h.speed()
		var events: Array[TimelineEvent] = sim.step()
		var missed: TimelineEvent = BattleProbe.first(events, &"missed")
		if missed != null:
			miss_count += 1
			check_eq(missed.detail, &"strike", "miss detail is action id")
			check(BattleProbe.first(events, &"damage") == null, "no damage on miss")
			check(BattleProbe.first(events, &"knocked_back") == null, "no knockback on miss")
			check(BattleProbe.first(events, &"interrupted") == null, "no cancel on miss")
			check(h.sp > 0, "SP was still gained on miss")
			check_eq(h.status_turns.get(&"confused", 0), 1, "confused turn decremented")
	check(miss_count >= 80 and miss_count <= 120, "miss rate over 200 seeds was %d (40-60%%)" % miss_count)


func test_friendly_moves_never_miss_when_confused() -> void:
	var confused := _status(&"confused", 0.5, 2)
	var friendly := BattleProbe.move(&"mend", {"power": 0, "target": &"self", "heal": 20})
	for seed_val: int in range(1, 51):
		var hero := BattleProbe.fighter(&"h", {"actions": [&"mend"] as Array[StringName]})
		var foe := BattleProbe.fighter(&"f", {"agility": 1})
		var sim: BattleSim = BattleProbe.sim([hero], [0], [foe], [0], [friendly], {}, [confused])
		sim.rng.seed = seed_val
		var h: UnitState = sim.timeline.find(&"h")
		h.apply_status(confused)
		h.hp = 50
		h.phase = UnitState.Phase.COMMAND
		sim.timeline.waiting_for = h
		sim.choose(&"h", friendly, &"")
		h.pos = Timeline.ACT_POINT - h.speed()
		var events: Array[TimelineEvent] = sim.step()
		check(BattleProbe.first(events, &"missed") == null, "friendly move never misses")
		check(BattleProbe.first(events, &"healed") != null, "friendly move healed")


func test_cure_qishr_cup_removes_confused_from_afflicted_only() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	check_eq(db.call("load_all"), PackedStringArray(), "content loads")
	var loader := BattleLoader.from_db(db, &"abu_nabil_duel")
	loader.start_bag = {&"qishr_cup": 1}
	var sim: BattleSim = loader.make_sim(&"grandfather_hilt", &"rustwire_blade", 1, 0, &"salvage_arm", &"wrist_rig")
	db.free()
	var zayd: UnitState = sim.timeline.find(&"zayd")
	var bilqis: UnitState = sim.timeline.find(&"bilqis")
	var confused: StatusDef = sim.statuses[&"confused"]
	zayd.apply_status(confused)
	zayd.phase = UnitState.Phase.COMMAND
	sim.timeline.waiting_for = zayd
	var reason: String = sim.choose_item(&"zayd", &"qishr_cup", &"")
	check_eq(reason, "", "chose qishr cup")
	zayd.pos = Timeline.ACT_POINT - zayd.speed()
	var events: Array[TimelineEvent] = sim.step()
	var ended_events: Array[TimelineEvent] = []
	for e: TimelineEvent in events:
		if e.kind == &"status_ended" and e.detail == &"confused":
			ended_events.append(e)
	check_eq(ended_events.size(), 1, "exactly one status_ended event")
	check_eq(ended_events[0].unit_id, &"zayd", "zayd cured of confusion")
	check(not zayd.status_turns.has(&"confused"), "zayd no longer confused")
	check(not bilqis.status_turns.has(&"confused"), "bilqis was not confused")


func test_uses_per_battle_limit_and_cancelled_cast_spends_use() -> void:
	var move := BattleProbe.move(&"feather_snack", {"target": &"self", "heal": 50, "uses_per_battle": 3})
	var hit := BattleProbe.move(&"hit", {"power": 10})
	var hero := BattleProbe.fighter(&"h", {"actions": [&"feather_snack", &"hit"] as Array[StringName]})
	var foe := BattleProbe.fighter(&"f", {"agility": 1})
	var sim: BattleSim = BattleProbe.sim([hero], [0], [foe], [0], [move, hit])
	var h: UnitState = sim.timeline.find(&"h")
	check_eq(sim.action_rules.uses_left(&"h", move), 3, "3 uses left at start")
	for i: int in 3:
		h.phase = UnitState.Phase.COMMAND
		sim.timeline.waiting_for = h
		check(sim.choices_for(h).has(move), "feather snack available for use %d" % (i + 1))
		check_eq(sim.choose(&"h", move, &""), "", "chosen %d" % (i + 1))
		sim.step()
	check_eq(sim.action_rules.uses_left(&"h", move), 0, "0 uses left")
	h.phase = UnitState.Phase.COMMAND
	sim.timeline.waiting_for = h
	check(not sim.choices_for(h).has(move), "feather snack no longer in choices")
	check_eq(sim.choose(&"h", move, &""), "'feather_snack' has no uses left", "refused 4th pick")
	# Cancelled cast spends use
	var sim2: BattleSim = BattleProbe.sim([hero], [0], [foe], [0], [move, hit])
	var h2: UnitState = sim2.timeline.find(&"h")
	h2.phase = UnitState.Phase.COMMAND
	sim2.timeline.waiting_for = h2
	check_eq(sim2.choose(&"h", move, &""), "", "first choice")
	check_eq(sim2.action_rules.uses_left(&"h", move), 2, "use spent at choose time")
	var breaker := BattleProbe.move(&"breaker", {"power": 10, "cancels_cast": true})
	sim2.timeline.hit(&"h", breaker)
	check_eq(h2.phase, UnitState.Phase.WAIT, "h interrupted")
	check_eq(sim2.action_rules.uses_left(&"h", move), 2, "interrupted cast still spent use")


func test_battle_ai_self_heal_and_spice_cloud_avoidance() -> void:
	var snack := BattleProbe.move(&"feather_snack", {"target": &"self", "heal": 80, "uses_per_battle": 3})
	var cloud := BattleProbe.move(&"spice_cloud", {"target": &"all_foes", "power": 4, "applies_status": &"confused"})
	var pot := BattleProbe.move(&"pot_swing", {"target": &"foe", "power": 16})
	var abu := BattleProbe.fighter(&"abu", {"max_hp": 900, "actions": [&"pot_swing", &"spice_cloud", &"feather_snack"] as Array[StringName]})
	var hero := BattleProbe.fighter(&"zayd", {"max_hp": 400})
	var confused := _status(&"confused", 0.5, 2)
	var sim: BattleSim = BattleProbe.sim([hero], [0], [abu], [0], [snack, cloud, pot], {"ai_heal_below": 0.4}, [confused])
	var abu_unit: UnitState = sim.timeline.find(&"abu_1")
	# Abu under 40% HP heals self with feather snack
	abu_unit.hp = 350
	var choice: BattleAI.Choice = BattleAI.pick(sim, abu_unit)
	check(choice != null and choice.action.id == &"feather_snack", "under 40% HP picks feather_snack")
	# Abu with 0 uses left will not pick feather snack
	sim.action_rules._uses[&"abu_1"] = {&"feather_snack": 3}
	choice = BattleAI.pick(sim, abu_unit)
	check(choice != null and choice.action.id != &"feather_snack", "0 uses left does not pick snack")
	# When party is fully confused, cloud (power 4) is not useful
	sim.action_rules._uses.clear()
	abu_unit.hp = 800
	var hero_unit: UnitState = sim.timeline.find(&"zayd")
	hero_unit.apply_status(confused)
	for seed_val: int in 20:
		sim.rng.seed = seed_val
		choice = BattleAI.pick(sim, abu_unit)
		check(choice != null and choice.action.id != &"spice_cloud", "never re-casts cloud on confused party")


func test_content_and_encounter_music() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	check_eq(db.call("load_all"), PackedStringArray(), "all content valid")
	var encounter := db.call("get_def", "encounter", &"abu_nabil_duel") as EncounterDef
	check(encounter != null, "abu_nabil_duel encounter exists")
	check_eq(encounter.music, &"boss_abu_nabil", "encounter music is boss_abu_nabil")
	var music: Def = db.call("get_def", "music", encounter.music) as Def
	check(music != null, "music boss_abu_nabil def exists")
	var abu := db.call("get_def", "combatant", &"abu_nabil") as CombatantDef
	check(abu != null, "abu_nabil combatant exists")
	check(abu.actions.has(&"pot_swing") and abu.actions.has(&"spice_cloud") and abu.actions.has(&"feather_snack"), "abu actions")
	for action_id: StringName in [&"pot_swing", &"spice_cloud", &"feather_snack"]:
		var a := db.call("get_def", "action", action_id) as ActionDef
		check(tr(a.name_key) != a.name_key, "%s has localized name" % action_id)
		check(tr(a.desc_key) != a.desc_key, "%s has localized desc" % action_id)
	check(tr("STATUS_CONFUSED") != "STATUS_CONFUSED", "STATUS_CONFUSED localized")
	check(tr("UI_MISS") != "UI_MISS", "UI_MISS localized")
	db.free()
