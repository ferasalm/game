class_name MapBattleEnd
extends RefCounted
## purpose: How a map fight pays out or starts again (docs/design/first-playable.md section 3): victory carries
## vitals and bag, awards XP and the encounter's riyal as BattleSession does; Retry restores the pre-battle snapshot.


## Returns [xp awarded, riyal paid] and writes the fight's result into GameState.
static func award(battle: MapBattle) -> Array[int]:
	var outcome: BattleOutcome = BattleOutcome.from_sim(battle.sim, &"victory")
	var encounter_id: StringName = battle.room.encounter
	var encounter := ContentDB.get_def("encounter", encounter_id) as EncounterDef
	var combatants: Dictionary[StringName, CombatantDef] = {}
	for id: StringName in ContentDB.ids("combatant"):
		combatants[id] = ContentDB.get_def("combatant", id) as CombatantDef
	var xp_base: int = Progression.encounter_xp(encounter, combatants)
	var was_cleared: bool = GameState.cleared_patrols.has(encounter_id)
	var rules := ContentDB.get_def("economy_rules", &"default") as EconomyRulesDef
	var share: float = rules.repeat_xp_share if (was_cleared and rules != null) else 1.0
	var xp_amount: int = floori(float(xp_base) * share)
	var levels := ContentDB.get_def("levels", &"default") as LevelsDef
	var classes: Dictionary[StringName, ClassDef] = {}
	for class_id: StringName in ContentDB.ids("class"):
		var class_def := ContentDB.get_def("class", class_id) as ClassDef
		classes[class_def.hero] = class_def
	var level_ups: Array[LevelUp] = Progression.award(GameState.xp, GameState.party, xp_amount, levels, classes)
	for lu: LevelUp in level_ups:
		if outcome.vitals.has(lu.hero):
			var vit: Dictionary = outcome.vitals[lu.hero]
			vit["hp"] = int(vit.get("hp", 0)) + lu.gains.get(&"max_hp", 0)
			vit["sp"] = int(vit.get("sp", 0)) + lu.gains.get(&"max_sp", 0)
	GameState.set_vitals(outcome.vitals)
	GameState.set_bag(outcome.bag)
	if not was_cleared:
		GameState.cleared_patrols.append(encounter_id)
	var reward: RewardResult = RewardApplier.victory(encounter_id)
	return [xp_amount, reward.money]


static func retry(battle: MapBattle) -> void:
	GameState.set_vitals(battle._pre_vitals.duplicate(true))
	GameState.set_bag(battle._pre_bag.duplicate(true))
	GameState.money = battle._pre_money
	battle.hud.queue_free()
	battle.hud = null
	battle._menu = null
	battle._ending = false
	battle._done = false
	battle._busy = false
	battle._seed = battle.seed_override if battle.seed_override >= 0 else battle._seed + 1
	MapBattleBuild.build(battle, battle._ambush)
	MapBattleBuild.place(battle)
