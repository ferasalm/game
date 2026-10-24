class_name BattleLoader
extends RefCounted
## Gathers the battle content from a loaded ContentDB and builds ready-to-run BattleSims
## for the default encounter. Fighters come from the pure gear logic (Gear.build_hero via PartyBuilder).

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
var armors: Dictionary[StringName, ArmorDef] = {}
var pistols: Dictionary[StringName, PistolDef] = {}
var accessories: Dictionary[StringName, AccessoryDef] = {}
var stones: Dictionary[StringName, StoneDef] = {}
var classes: Dictionary[StringName, ClassDef] = {}
var levels: LevelsDef
var perks: Dictionary[StringName, PerkDef] = {}
var loadouts: Dictionary[StringName, LoadoutDef] = {}
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
	for armor_id: StringName in db.call("ids", "armor"):
		loader.armors[armor_id] = db.call("get_def", "armor", armor_id) as ArmorDef
	for part_id: StringName in db.call("ids", "pistol"):
		loader.pistols[part_id] = db.call("get_def", "pistol", part_id) as PistolDef
	for ring_id: StringName in db.call("ids", "accessory"):
		loader.accessories[ring_id] = db.call("get_def", "accessory", ring_id) as AccessoryDef
	for stone_id: StringName in db.call("ids", "stone"):
		loader.stones[stone_id] = db.call("get_def", "stone", stone_id) as StoneDef
	for class_id: StringName in db.call("ids", "class"):
		loader.classes[class_id] = db.call("get_def", "class", class_id) as ClassDef
	loader.levels = db.call("get_def", "levels", &"default") as LevelsDef
	for perk_id: StringName in db.call("ids", "perk"):
		loader.perks[perk_id] = db.call("get_def", "perk", perk_id) as PerkDef
	for loadout_id: StringName in db.call("ids", "loadout"):
		loader.loadouts[loadout_id] = db.call("get_def", "loadout", loadout_id) as LoadoutDef
	return loader


func fighter(hero_id: StringName, hilt_id: StringName, blade_id: StringName, prosthetic_id: StringName) -> CombatantDef:
	return Gear.build(combatants.get(hero_id), hilts.get(hilt_id), blades.get(blade_id), prosthetics.get(prosthetic_id), perks)


func zayd_with(hilt_id: StringName, blade_id: StringName, prosthetic_id: StringName = &"") -> CombatantDef:
	return fighter(&"zayd", hilt_id, blade_id, prosthetic_id)


## The hero's fighter from a GameState (equipment, sockets, upgrades, xp); the assembly lives in PartyBuilder.
func hero_from_state(hero_id: StringName, game_state: Object = null) -> CombatantDef:
	return PartyBuilder.hero(self, hero_id, game_state)


func party_from_equipment(
		equipment: Dictionary[StringName, StringName], hero_ids: Array[StringName] = []) -> Array[CombatantDef]:
	return PartyBuilder.party_from_equipment(self, equipment, hero_ids)


func party_from_state(game_state: Object, hero_ids: Array[StringName] = []) -> Array[CombatantDef]:
	return PartyBuilder.party_from_state(self, game_state, hero_ids)


## A sim for the two start heroes: explicit Zayd gear, Bilqis's rig plus pistol parts
## (empty ids fall back to her start pistol) at one hero level.
func make_sim(
		hilt_id: StringName, blade_id: StringName, battle_seed: int, ambush: int = 0,
		zayd_prosthetic: StringName = &"", bilqis_prosthetic: StringName = &"",
		hero_level: int = 1, frame_id: StringName = &"", barrel_id: StringName = &"") -> BattleSim:
	var zayd_state := GearState.new()
	zayd_state.base = combatants.get(&"zayd")
	zayd_state.hilt = hilts.get(hilt_id)
	zayd_state.blade = blades.get(blade_id)
	zayd_state.prosthetic = prosthetics.get(zayd_prosthetic)
	zayd_state.level = hero_level
	zayd_state.perks = perks
	for c: ClassDef in classes.values():
		if c.hero == &"zayd":
			zayd_state.class_def = c
			break
	var zayd_fighter := Gear.build_hero(&"zayd", zayd_state)
	var bilqis_state := GearState.new()
	bilqis_state.base = combatants.get(&"bilqis")
	bilqis_state.prosthetic = prosthetics.get(bilqis_prosthetic)
	bilqis_state.level = hero_level
	bilqis_state.perks = perks
	var bilqis_start: LoadoutDef = _start_loadout_of(&"bilqis")
	bilqis_state.frame = pistols.get(frame_id if frame_id != &"" else bilqis_start.frame)
	bilqis_state.barrel = pistols.get(barrel_id if barrel_id != &"" else bilqis_start.barrel)
	bilqis_state.accessory = accessories.get(bilqis_start.accessory)
	for c: ClassDef in classes.values():
		if c.hero == &"bilqis":
			bilqis_state.class_def = c
			break
	var bilqis_fighter := Gear.build_hero(&"bilqis", bilqis_state)
	return make_sim_for([zayd_fighter, bilqis_fighter], battle_seed, ambush)


func make_sim_for(party: Array[CombatantDef], battle_seed: int, ambush: int = 0) -> BattleSim:
	return BattleSim.create_from(make_setup(party, battle_seed, ambush))


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
	setup.can_flee = encounter.can_flee
	if economy != null:
		setup.ko_stand_hp = economy.ko_stand_hp
	return setup


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


func _start_loadout_of(hero_id: StringName) -> LoadoutDef:
	for start: LoadoutDef in loadouts.values():
		if start.hero == hero_id:
			return start
	var none := LoadoutDef.new()
	none.hero = hero_id
	return none
