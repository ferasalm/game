class_name BattleLoader
extends RefCounted
## Gathers the battle content from a loaded ContentDB (passed in as a Node) and builds ready-to-run BattleSims
## for the default encounter. Fighters come from the pure gear logic (Gear.build). Used by the prototype, the
## balance harness and the tests.

var rules: BattleRulesDef
var encounter: EncounterDef
var actions: Dictionary[StringName, ActionDef] = {}
var statuses: Dictionary[StringName, StatusDef] = {}
var combatants: Dictionary[StringName, CombatantDef] = {}
var hilts: Dictionary[StringName, HiltDef] = {}
var blades: Dictionary[StringName, BladeDef] = {}
var prosthetics: Dictionary[StringName, ProstheticDef] = {}
var perks: Dictionary[StringName, PerkDef] = {}
var loadouts: Dictionary[StringName, LoadoutDef] = {}


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
	for prosthetic_id: StringName in db.call("ids", "prosthetic"):
		loader.prosthetics[prosthetic_id] = db.call("get_def", "prosthetic", prosthetic_id) as ProstheticDef
	for perk_id: StringName in db.call("ids", "perk"):
		loader.perks[perk_id] = db.call("get_def", "perk", perk_id) as PerkDef
	for loadout_id: StringName in db.call("ids", "loadout"):
		loader.loadouts[loadout_id] = db.call("get_def", "loadout", loadout_id) as LoadoutDef
	return loader


## A hero built from the shared base and the named gear (empty or unknown ids mean none).
func fighter(hero_id: StringName, hilt_id: StringName, blade_id: StringName, prosthetic_id: StringName) -> CombatantDef:
	return Gear.build(combatants[hero_id], hilts.get(hilt_id), blades.get(blade_id), prosthetics.get(prosthetic_id), perks)


## Zayd with the given hilt and blade (and prosthetic, default none) equipped (a new CombatantDef).
func zayd_with(hilt_id: StringName, blade_id: StringName, prosthetic_id: StringName = &"") -> CombatantDef:
	return fighter(&"zayd", hilt_id, blade_id, prosthetic_id)


## Zayd and Bilqis as GameState.equipment says (a missing slot falls back to that hero's start loadout).
func party_from_equipment(equipment: Dictionary[StringName, StringName]) -> Array[CombatantDef]:
	var party: Array[CombatantDef] = []
	for hero_id: StringName in [&"zayd", &"bilqis"]:
		var start: LoadoutDef = _start_of(hero_id)
		party.append(fighter(
			hero_id, Loadout.worn(equipment, start, &"hilt"), Loadout.worn(equipment, start, &"blade"),
			Loadout.worn(equipment, start, &"prosthetic")))
	return party


## A fresh battle: Zayd (with the chosen gear) and Bilqis (with her prosthetic, default none) against the
## encounter's enemies.
func make_sim(
		hilt_id: StringName, blade_id: StringName, battle_seed: int, ambush: int = 0,
		zayd_prosthetic: StringName = &"", bilqis_prosthetic: StringName = &"") -> BattleSim:
	var party: Array[CombatantDef] = [
		zayd_with(hilt_id, blade_id, zayd_prosthetic), fighter(&"bilqis", &"", &"", bilqis_prosthetic)]
	return make_sim_for(party, battle_seed, ambush)


## A fresh battle for an already built party.
func make_sim_for(party: Array[CombatantDef], battle_seed: int, ambush: int = 0) -> BattleSim:
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


func _start_of(hero_id: StringName) -> LoadoutDef:
	for start: LoadoutDef in loadouts.values():
		if start.hero == hero_id:
			return start
	var none := LoadoutDef.new()
	none.hero = hero_id
	return none
