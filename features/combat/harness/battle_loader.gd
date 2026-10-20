class_name BattleLoader
extends RefCounted
## Gathers the battle content from a loaded ContentDB (passed in as a Node) and builds ready-to-run BattleSims
## for the default encounter. Used by the balance harness and the tests; also a model for the battle view.

var rules: BattleRulesDef
var encounter: EncounterDef
var actions: Dictionary[StringName, ActionDef] = {}
var statuses: Dictionary[StringName, StatusDef] = {}
var combatants: Dictionary[StringName, CombatantDef] = {}
var hilts: Dictionary[StringName, HiltDef] = {}
var blades: Dictionary[StringName, BladeDef] = {}


static func from_db(db: Node, encounter_id: StringName = &"rooftop_patrol") -> BattleLoader:
	var loader := BattleLoader.new()
	loader.rules = db.call("get_def", "battle_rules", &"default") as BattleRulesDef
	loader.encounter = db.call("get_def", "encounter", encounter_id) as EncounterDef
	for action_id: StringName in db.call("ids", "action"):
		loader.actions[action_id] = db.call("get_def", "action", action_id) as ActionDef
	for status_id: StringName in db.call("ids", "status"):
		loader.statuses[status_id] = db.call("get_def", "status", status_id) as StatusDef
	for combatant_id: StringName in db.call("ids", "combatant"):
		loader.combatants[combatant_id] = db.call("get_def", "combatant", combatant_id) as CombatantDef
	for hilt_id: StringName in db.call("ids", "hilt"):
		loader.hilts[hilt_id] = db.call("get_def", "hilt", hilt_id) as HiltDef
	for blade_id: StringName in db.call("ids", "blade"):
		loader.blades[blade_id] = db.call("get_def", "blade", blade_id) as BladeDef
	return loader


## Zayd with the given hilt and blade equipped (a new CombatantDef).
func zayd_with(hilt_id: StringName, blade_id: StringName) -> CombatantDef:
	return Djanbeyyah.equip(combatants[&"zayd"], hilts[hilt_id], blades[blade_id])


## A fresh battle: Zayd (with the chosen pairing) and Bilqis against the encounter's enemies.
func make_sim(hilt_id: StringName, blade_id: StringName, battle_seed: int, ambush: int = 0) -> BattleSim:
	var party: Array[CombatantDef] = [zayd_with(hilt_id, blade_id), combatants[&"bilqis"]]
	var foes: Array[CombatantDef] = []
	for enemy_id: StringName in encounter.enemies:
		foes.append(combatants[enemy_id])
	return BattleSim.create(
		rules, party, encounter.party_slots, foes, encounter.enemy_slots, battle_seed, ambush, actions, statuses)


## Plays a battle to its end with BattleAI choosing for the heroes too. Returns every event, in order.
static func autoplay(sim: BattleSim) -> Array[TimelineEvent]:
	var trace: Array[TimelineEvent] = []
	var guard: int = sim.rules.max_ticks * 4
	while sim.result == &"" and guard > 0:
		guard -= 1
		var hero: UnitState = sim.waiting_hero()
		if hero != null:
			sim.auto_choose(hero)
		trace.append_array(sim.step())
	return trace
