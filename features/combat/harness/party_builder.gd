class_name PartyBuilder
extends RefCounted
## Fills GearStates and builds hero fighters / parties from saved equipment or a GameState through one
## BattleLoader's content dictionaries (used through BattleLoader's hero_from_state / party_* delegates).


## The hero's fighter built from the loader's content plus the saved state (pure: base is never touched).
static func hero(loader: BattleLoader, hero_id: StringName, game_state: Object = null) -> CombatantDef:
	var state: GearState = _bare_state(loader, hero_id)
	if game_state != null:
		var hero_xp: int = int(game_state.get("xp").get(hero_id, 0)) if "xp" in game_state else 0
		state.level = Progression.level(hero_xp, loader.levels)
		var equip: Dictionary = game_state.get("equipment") if "equipment" in game_state else {}
		var worn_ids := _wear_saved(loader, state, hero_id, equip, _start_of(loader, hero_id))
		if "sockets" in game_state:
			var sockets: Dictionary = game_state.get("sockets")
			_socket_stones(loader, sockets, worn_ids[&"hilt"], state.socketed_stones)
			_socket_stones(loader, sockets, worn_ids[&"accessory"], state.accessory_stones)
		if "upgrades" in game_state:
			state.upgrades = game_state.get("upgrades")
	return Gear.build_hero(hero_id, state)


## The whole party from a saved equipment dictionary (each hero's choice, else the start loadout).
static func party_from_equipment(
		loader: BattleLoader, equipment: Dictionary[StringName, StringName],
		hero_ids: Array[StringName] = []) -> Array[CombatantDef]:
	var party: Array[CombatantDef] = []
	for hero_id: StringName in _heroes(loader, hero_ids):
		var state: GearState = _bare_state(loader, hero_id)
		_wear_saved(loader, state, hero_id, equipment, _start_of(loader, hero_id))
		party.append(Gear.build_hero(hero_id, state))
	return party


## The whole party from a GameState (saved choices, sockets, upgrades and xp included).
static func party_from_state(
		loader: BattleLoader, game_state: Object, hero_ids: Array[StringName] = []) -> Array[CombatantDef]:
	var party: Array[CombatantDef] = []
	for hero_id: StringName in _heroes(loader, hero_ids):
		party.append(hero(loader, hero_id, game_state))
	return party


## The hero list to build for: the caller's list, else the economy's start party.
static func _heroes(loader: BattleLoader, hero_ids: Array[StringName]) -> Array[StringName]:
	return hero_ids if not hero_ids.is_empty() else loader.economy.start_party


## The start loadout of one hero (an empty loadout for a hero without one).
static func _start_of(loader: BattleLoader, hero_id: StringName) -> LoadoutDef:
	for start: LoadoutDef in loader.loadouts.values():
		if start.hero == hero_id:
			return start
	var none := LoadoutDef.new()
	none.hero = hero_id
	return none


static func _bare_state(loader: BattleLoader, hero_id: StringName) -> GearState:
	var state := GearState.new()
	state.base = loader.combatants.get(hero_id)
	state.perks = loader.perks
	for c: ClassDef in loader.classes.values():
		if c.hero == hero_id:
			state.class_def = c
			break
	return state


## Wears what the equipment dict says, else the start loadout (armor comes from the equipment only).
## Returns the worn item ids by part ("hilt" and "accessory" are the socket holders).
static func _wear_saved(
		loader: BattleLoader, state: GearState, hero_id: StringName,
		equipment: Dictionary, start: LoadoutDef) -> Dictionary[StringName, StringName]:
	var worn_ids: Dictionary[StringName, StringName] = {}
	for part: StringName in [&"hilt", &"blade", &"prosthetic", &"frame", &"barrel", &"accessory"]:
		var item_id: StringName = Loadout.worn(equipment, start, part)
		worn_ids[part] = item_id
		match part:
			&"hilt":
				state.hilt = loader.hilts.get(item_id)
			&"blade":
				state.blade = loader.blades.get(item_id)
			&"prosthetic":
				state.prosthetic = loader.prosthetics.get(item_id)
			&"frame":
				state.frame = loader.pistols.get(item_id)
			&"barrel":
				state.barrel = loader.pistols.get(item_id)
			&"accessory":
				state.accessory = loader.accessories.get(item_id)
	var armor_id: StringName = equipment.get(Inventory.slot_key(hero_id, &"armor"), &"")
	state.armor = loader.armors.get(armor_id)
	return worn_ids


## Appends every known stone socketed in the worn item's socket list to out.
static func _socket_stones(
		loader: BattleLoader, sockets: Dictionary, item_id: StringName, out: Array[StoneDef]) -> void:
	if item_id == &"":
		return
	for stone_name: Variant in (sockets.get(item_id, []) as Array):
		var s_id := StringName(str(stone_name))
		if loader.stones.has(s_id):
			out.append(loader.stones[s_id])
