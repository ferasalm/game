class_name MapBattleEnd
extends RefCounted
## purpose: How a map fight pays out or starts again (docs/design/first-playable.md section 3): victory carries
## vitals and bag, awards XP and the encounter's riyal as BattleSession does; Retry restores the pre-battle snapshot.


## Returns [xp awarded, riyal paid] and writes the fight's result into GameState.
static func award(battle: MapBattle) -> Array[int]:
	var outcome: BattleOutcome = BattleOutcome.from_sim(battle.sim, &"victory")
	var encounter := ContentDB.get_def("encounter", battle.room.encounter) as EncounterDef
	var combatants: Dictionary[StringName, CombatantDef] = {}
	for id: StringName in ContentDB.ids("combatant"):
		combatants[id] = ContentDB.get_def("combatant", id) as CombatantDef
	var xp_amount: int = Progression.encounter_xp(encounter, combatants)
	var levels := ContentDB.get_def("levels", &"default") as LevelsDef
	var classes: Dictionary[StringName, ClassDef] = {}
	for class_id: StringName in ContentDB.ids("class"):
		var class_def := ContentDB.get_def("class", class_id) as ClassDef
		classes[class_def.hero] = class_def
	Progression.award(GameState.xp, GameState.party, xp_amount, levels, classes)
	GameState.set_vitals(outcome.vitals)
	GameState.set_bag(outcome.bag)
	var reward: RewardResult = RewardApplier.victory(battle.room.encounter)
	return [xp_amount, reward.money]


static func retry(battle: MapBattle) -> void:
	GameState.set_vitals(battle._pre_vitals)
	GameState.set_bag(battle._pre_bag)
	GameState.money = battle._pre_money
	battle.hud.queue_free()
	battle.hud = null
	battle._menu = null
	battle._ending = false
	battle._done = false
	battle._busy = false
	battle._seed += 1
	MapBattleBuild.build(battle, false)
	MapBattleBuild.place(battle)
