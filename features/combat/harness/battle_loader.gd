class_name BattleLoader
extends RefCounted
## Gathers the battle content from a loaded ContentDB and builds ready-to-run BattleSims
## for the default encounter. Fighters come from the pure gear logic (Gear.build_hero).

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


func hero_from_state(hero_id: StringName, game_state: Object = null) -> CombatantDef:
	var state := GearState.new()
	state.base = combatants.get(hero_id)
	state.perks = perks
	for c: ClassDef in classes.values():
		if c.hero == hero_id:
			state.class_def = c
			break
	if game_state != null:
		var hero_xp: int = int(game_state.get("xp").get(hero_id, 0)) if "xp" in game_state else 0
		state.level = Progression.level(hero_xp, levels)
		var equip: Dictionary = game_state.get("equipment") if "equipment" in game_state else {}
		var start: LoadoutDef = _start_of(hero_id)
		var hilt_id: StringName = Loadout.worn(equip, start, &"hilt")
		var blade_id: StringName = Loadout.worn(equip, start, &"blade")
		var prosthetic_id: StringName = Loadout.worn(equip, start, &"prosthetic")
		var armor_id: StringName = equip.get(Inventory.slot_key(hero_id, &"armor"), &"")
		state.armor = armors.get(armor_id)
		state.hilt = hilts.get(hilt_id)
		state.blade = blades.get(blade_id)
		state.prosthetic = prosthetics.get(prosthetic_id)
		if "sockets" in game_state and hilt_id != &"":
			var sock_list: Array = game_state.get("sockets").get(hilt_id, [])
			for stone_name: Variant in sock_list:
				var s_id := StringName(str(stone_name))
				if stones.has(s_id):
					state.socketed_stones.append(stones[s_id])
		if "upgrades" in game_state:
			state.upgrades = game_state.get("upgrades")
	return Gear.build_hero(hero_id, state)


func zayd_with(hilt_id: StringName, blade_id: StringName, prosthetic_id: StringName = &"") -> CombatantDef:
	return fighter(&"zayd", hilt_id, blade_id, prosthetic_id)


func party_from_equipment(
		equipment: Dictionary[StringName, StringName], hero_ids: Array[StringName] = []) -> Array[CombatantDef]:
	var party: Array[CombatantDef] = []
	var ids: Array[StringName] = hero_ids if not hero_ids.is_empty() else economy.start_party
	for hero_id: StringName in ids:
		var start: LoadoutDef = _start_of(hero_id)
		var state := GearState.new()
		state.base = combatants.get(hero_id)
		state.perks = perks
		for c: ClassDef in classes.values():
			if c.hero == hero_id:
				state.class_def = c
				break
		state.hilt = hilts.get(Loadout.worn(equipment, start, &"hilt"))
		state.blade = blades.get(Loadout.worn(equipment, start, &"blade"))
		state.prosthetic = prosthetics.get(Loadout.worn(equipment, start, &"prosthetic"))
		var armor_id: StringName = equipment.get(Inventory.slot_key(hero_id, &"armor"), &"")
		state.armor = armors.get(armor_id)
		party.append(Gear.build_hero(hero_id, state))
	return party


func party_from_state(game_state: Object, hero_ids: Array[StringName] = []) -> Array[CombatantDef]:
	var party: Array[CombatantDef] = []
	var ids: Array[StringName] = hero_ids if not hero_ids.is_empty() else economy.start_party
	for hero_id: StringName in ids:
		party.append(hero_from_state(hero_id, game_state))
	return party


func make_sim(
		hilt_id: StringName, blade_id: StringName, battle_seed: int, ambush: int = 0,
		zayd_prosthetic: StringName = &"", bilqis_prosthetic: StringName = &"",
		hero_level: int = 1) -> BattleSim:
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


func _start_of(hero_id: StringName) -> LoadoutDef:
	for start: LoadoutDef in loadouts.values():
		if start.hero == hero_id:
			return start
	var none := LoadoutDef.new()
	none.hero = hero_id
	return none
