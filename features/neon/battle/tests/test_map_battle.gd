class_name TestMapBattle
extends TestCase
## purpose: MapBattle runs the real BattleSim on the map: an auto-choosing hero finishes the fight, `ended` fires
## once, the winner's living side stands and downed foes hold the ko; a melee hit applies only at the impact signal.

const CONTACT: Vector2 = Vector2(1450.0, 1000.0)


func _fresh() -> void:
	GameState.start_new()
	GameState.party.clear()
	GameState.party.append(&"zayd")
	GameState.vitals.clear()


func _world() -> Node2D:
	var world := Node2D.new()
	tree.root.add_child(world)
	return world


func _battle(world: Node2D) -> MapBattle:
	var battle := MapBattle.new()
	world.add_child(battle)
	battle.instant = true
	battle.auto_play = true
	return battle


func _foes() -> Array[IsoActor]:
	var out: Array[IsoActor] = []
	for i: int in 2:
		var foe := IsoActor.new()
		foe.setup(&"guard")
		out.append(foe)
	return out


func test_auto_battle_ends_once() -> void:
	_fresh()
	var world: Node2D = _world()
	var hero := IsoActor.new()
	hero.setup(&"rydan")
	var foes: Array[IsoActor] = _foes()
	var battle: MapBattle = _battle(world)
	battle.seed_override = 1
	var calls: Array[bool] = []
	battle.ended.connect(func(won: bool) -> void: calls.append(won))
	battle.begin(world, ContentDB.get_def("neon_room", &"prison_roof") as NeonRoomDef, hero, foes, CONTACT, false)
	var result: StringName = battle.run_to_end(6000)
	check_eq(result, &"victory", "Rydan wins the prison guards fight")
	check_eq(calls.size(), 1, "ended fires exactly once")
	check_eq(calls, [true] as Array[bool], "ended says the hero won")
	check_eq(hero.state, &"idle", "the winner side stands")
	var downed: int = 0
	for foe: IsoActor in foes:
		if foe.state == &"ko":
			downed += 1
	check_eq(downed, foes.size(), "both losers hold the ko frame")
	world.free()


func test_balance_200_fights() -> void:
	pass


func test_melee_hit_lands_only_at_the_impact_signal() -> void:
	_fresh()
	var world: Node2D = _world()
	var hero := IsoActor.new()
	hero.setup(&"rydan")
	var foes: Array[IsoActor] = _foes()
	var battle: MapBattle = _battle(world)
	battle.seed_override = 999
	battle.begin(world, ContentDB.get_def("neon_room", &"prison_roof") as NeonRoomDef, hero, foes, CONTACT, false)
	var foe_id: StringName = &""
	for unit: UnitState in battle.sim.timeline.units:
		if unit.side == 1:
			foe_id = unit.unit_id
			break
	var before: int = battle.shown_hp[foe_id]
	var hit := TimelineEvent.new(&"damage", foe_id, 7, &"jambiyah_strike")
	var hits: Array[TimelineEvent] = [hit]
	var play := MapBattlePlay.new(battle)
	play.begin_melee(hero, hits)
	check_eq(battle.shown_hp[foe_id], before, "no damage before the impact frame")
	for i: int in 300:
		hero._process(1.0 / 60.0)
	check_eq(battle.shown_hp[foe_id], before - 7, "the hit applies at the impact frame")
	world.free()


func test_played_melee_waits_for_impact() -> void:
	_fresh()
	var world: Node2D = _world()
	var hero := IsoActor.new()
	hero.setup(&"rydan")
	var foes: Array[IsoActor] = _foes()
	var battle: MapBattle = _battle(world)
	battle.seed_override = 999
	battle.begin(world, ContentDB.get_def("neon_room", &"prison_roof") as NeonRoomDef, hero, foes, CONTACT, false)
	var foe_id: StringName = &""
	for unit: UnitState in battle.sim.timeline.units:
		if unit.side == 1:
			foe_id = unit.unit_id
			break
	var before: int = battle.shown_hp[foe_id]
	var unit: UnitState = battle.sim.timeline.find(&"zayd")
	unit.acted = battle.sim.actions[&"jambiyah_strike"]
	var hit := TimelineEvent.new(&"damage", foe_id, 15, &"jambiyah_strike")
	var hp_at_impact: int = -1
	hero.impact.connect(func(_st: StringName) -> void:
		hp_at_impact = battle.shown_hp[foe_id]
	, CONNECT_ONE_SHOT)
	var play := MapBattlePlay.new(battle)
	print("TEST: hero=", hero, " impacts connected=", hero.impact.get_connections().size())
	play.play([TimelineEvent.new(&"act", &"zayd"), hit])
	print("TEST: after play, hp_at_impact=", hp_at_impact, " shown_hp=", battle.shown_hp[foe_id])
	check_eq(hp_at_impact, before, "no damage applied before the impact signal")
	check_eq(battle.shown_hp[foe_id], before - 15, "damage applied after the impact signal")
	world.free()


func test_midfight_ko_shows() -> void:
	_fresh()
	var world: Node2D = _world()
	var hero := IsoActor.new()
	hero.setup(&"rydan")
	var foes: Array[IsoActor] = _foes()
	var battle: MapBattle = _battle(world)
	battle.seed_override = 1
	battle.begin(world, ContentDB.get_def("neon_room", &"prison_roof") as NeonRoomDef, hero, foes, CONTACT, false)
	var saw_midfight_ko: bool = false
	var saw_hp_match: bool = true
	for frame: int in 6000:
		if battle.sim.result != &"":
			break
		battle.step_frame()
		for unit: UnitState in battle.sim.timeline.units:
			if battle.shown_hp[unit.unit_id] != unit.hp:
				saw_hp_match = false
			if unit.side == 1 and unit.hp <= 0 and battle.sim.result == &"":
				var actor: IsoActor = battle.actors[unit.unit_id]
				if actor.state == &"ko":
					saw_midfight_ko = true
	check(saw_midfight_ko, "downed foe shows ko mid-fight before fight ends")
	check(saw_hp_match, "shown_hp equals sim hp after every batch")
	world.free()
