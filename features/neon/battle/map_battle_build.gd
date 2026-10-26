class_name MapBattleBuild
extends RefCounted
## purpose: Builds the map fight (docs/design/first-playable.md section 3): the sim from the room's encounter and
## the party from GameState, the MapFormation spots, the IsoActor to unit mapping and the HUD.

const HERO_ID: StringName = &"zayd"


static func build(battle: MapBattle, ambush: bool) -> void:
	battle._loader = BattleLoader.from_db(ContentDB, battle.room.encounter)
	var party: Array[CombatantDef] = battle._loader.party_from_state(GameState, [HERO_ID])
	battle.sim = battle._loader.make_sim_for(party, battle._seed, 1 if ambush else 0)
	battle._battle_view = ContentDB.get_def("battle_view", &"default") as BattleViewDef
	battle.actors.clear()
	battle.shown_hp.clear()
	var formation: Dictionary = MapFormation.spots(battle._contact, battle._foes.size(),
		battle.room.walk, battle.room.holes)
	battle._hero_spot = formation["hero"]
	battle._foe_spots.assign(formation["foes"])
	attach(battle, battle._hero, battle._hero_spot)
	battle.actors[HERO_ID] = battle._hero
	var enemy_units: Array[UnitState] = []
	for unit: UnitState in battle.sim.timeline.units:
		if unit.side == 1:
			enemy_units.append(unit)
	for i: int in mini(battle._foes.size(), enemy_units.size()):
		var spot: Vector2 = battle._foe_spots[i] if i < battle._foe_spots.size() else battle._contact
		attach(battle, battle._foes[i], spot)
		battle.actors[enemy_units[i].unit_id] = battle._foes[i]
	for unit: UnitState in battle.sim.timeline.units:
		battle.shown_hp[unit.unit_id] = unit.hp
	battle.hud = MapBattleHud.new()
	battle.add_child(battle.hud)
	battle.hud.setup(battle.sim, battle.view, battle._battle_view, battle.shown_hp, battle.actors)
	battle.hud.retry_chosen.connect(battle._on_retry)
	battle.hud.quit_chosen.connect(battle._on_quit)
	battle._play = MapBattlePlay.new(battle)
	battle._menu = null


static func attach(battle: MapBattle, actor: IsoActor, spot: Vector2) -> void:
	if actor == null:
		return
	if not actor.is_inside_tree():
		battle._world.add_child(actor)
	if not battle.instant:
		return
	actor.position = spot
	actor.play(&"idle", true)


static func place(battle: MapBattle) -> void:
	battle._hero.position = battle._hero_spot
	battle._hero.play(&"idle", true)
	battle._hero.face(battle._contact - battle._hero.position)
	for i: int in battle._foes.size():
		var foe: IsoActor = battle._foes[i]
		foe.position = battle._foe_spots[i] if i < battle._foe_spots.size() else battle._contact
		foe.play(&"idle", true)
		foe.face(battle._hero.position - foe.position)


## The winner's living side stands; every downed unit holds the ko's last frame.
static func pose_winner(battle: MapBattle, won: bool) -> void:
	for unit: UnitState in battle.sim.timeline.units:
		var actor: IsoActor = battle.actors.get(unit.unit_id)
		if actor == null:
			continue
		if unit.hp <= 0:
			actor.play(&"ko", true)
		elif (unit.side == 0) == won:
			actor.play(&"idle", true)
