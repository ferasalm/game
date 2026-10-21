class_name BattleLoader
extends RefCounted
## Gathers the battle content from a loaded ContentDB (passed in as a Node) and builds ready-to-run BattleSims
## for the default encounter. Fighters come from the pure gear logic (Gear.build). Used by the prototype, the
## balance harness and the tests.

var rules: BattleRulesDef
var economy: EconomyRulesDef
var encounter: EncounterDef
var actions: Dictionary[StringName, ActionDef] = {}
var statuses: Dictionary[StringName, StatusDef] = {}
var consumables: Dictionary[StringName, ConsumableDef] = {}
var combatants: Dictionary[StringName, CombatantDef] = {}
var hilts: Dictionary[StringName, HiltDef] = {}
var blades: Dictionary[StringName, BladeDef] = {}
var prosthetics: Dictionary[StringName, ProstheticDef] = {}
var perks: Dictionary[StringName, PerkDef] = {}
var loadouts: Dictionary[StringName, LoadoutDef] = {}
## Herbs {consumable id: count} every fight made here starts with (the balance harness sets it).
var start_bag: Dictionary = {}


static func from_db(db: Node, encounter_id: StringName = &"rooftop_patrol") -> BattleLoader:
	var loader := BattleLoader.new()
	loader.rules = db.call("get_def", "battle_rules", &"default") as BattleRulesDef
	loader.encounter = db.call("get_def", "encounter", encounter_id) as EncounterDef
	loader.economy = db.call("get_def", "economy_rules", &"default") as EconomyRulesDef
	for action_id: StringName in db.call("ids", "action"):
		loader.actions[action_id] = db.call("get_def", "action", action_id) as ActionDef
	for status_id: StringName in db.call("ids", "status"):
		loader.statuses[status_id] = db.call("get_def", "status", status_id) as StatusDef
	for item_id: StringName in db.call("ids", "consumable"):
		loader.consumables[item_id] = db.call("get_def", "consumable", item_id) as ConsumableDef
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


## The heroes as GameState.equipment says (a missing slot falls back to that hero's start loadout). hero_ids is
## the party list; empty means the new-game party of content/economy/rules.json.
func party_from_equipment(
		equipment: Dictionary[StringName, StringName], hero_ids: Array[StringName] = []) -> Array[CombatantDef]:
	var party: Array[CombatantDef] = []
	var ids: Array[StringName] = hero_ids if not hero_ids.is_empty() else economy.start_party
	for hero_id: StringName in ids:
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


## A fresh battle for an already built party (everyone at full, no herbs).
func make_sim_for(party: Array[CombatantDef], battle_seed: int, ambush: int = 0) -> BattleSim:
	return BattleSim.create_from(make_setup(party, battle_seed, ambush))


## The BattleSetup for the encounter and a built party; the caller fills vitals, bag, equipment, arena and anchor.
func make_setup(party: Array[CombatantDef], battle_seed: int, ambush: int = 0) -> BattleSetup:
	var setup := BattleSetup.new()
	setup.rules = rules
	setup.party = party
	setup.party_slots = encounter.party_slots
	for enemy_id: StringName in encounter.enemies:
		setup.enemies.append(combatants[enemy_id])
	setup.enemy_slots = encounter.enemy_slots
	setup.actions = actions
	setup.statuses = statuses
	setup.consumables = consumables
	setup.bag = start_bag.duplicate()
	setup.seed = battle_seed
	setup.ambush = ambush
	setup.encounter_id = encounter.id
	if economy != null:
		setup.ko_stand_hp = economy.ko_stand_hp
	return setup


## Plays a battle to its end with BattleAI choosing for the heroes too (use_items: ItemPolicy may spend herbs
## first). Returns every event, in order.
static func autoplay(sim: BattleSim, use_items: bool = false) -> Array[TimelineEvent]:
	var trace: Array[TimelineEvent] = []
	var guard: int = sim.rules.max_ticks * 4
	while sim.result == &"" and guard > 0:
		guard -= 1
		var hero: UnitState = sim.waiting_hero()
		if hero != null and not (use_items and ItemPolicy.try_use(sim, hero)):
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
