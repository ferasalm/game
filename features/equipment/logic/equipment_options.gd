class_name EquipmentOptions
extends RefCounted
## Pure rules of the equipment screen: which slots a hero has, which OWNED items fit a slot (best rarity first),
## which items a hero wears now, the fighter built from a staged set of items, and writing a staged set into
## the saved equipment through Inventory.equip. Items and perks are passed in (looked up by the view).


## "rydan" -> blade, hilt, armor, prosthetic, accessory; "bilqis" -> frame, barrel, armor, prosthetic,
## accessory; every other hero -> armor, prosthetic, accessory.
static func parts_for(hero: StringName) -> Array[StringName]:
	if hero == Jambiyah.WIELDER:
		return [&"blade", &"hilt", &"armor", &"prosthetic", &"accessory"]
	if hero == Pistol.WIELDER:
		return [&"frame", &"barrel", &"armor", &"prosthetic", &"accessory"]
	return [&"armor", &"prosthetic", &"accessory"]


## The owned items that may be worn in the hero's slot, rarer first, then by id. rarity_order: rarity id -> order.
static func options(
		owned: Array[StringName], items: Array[EquipDef], hero: StringName, part: StringName,
		rarity_order: Dictionary[StringName, int]) -> Array[EquipDef]:
	var out: Array[EquipDef] = []
	var slot: StringName = Inventory.slot_key(hero, part)
	for item: EquipDef in items:
		if Inventory.equip_problem(owned, slot, item).is_empty():
			out.append(item)
	out.sort_custom(func(a: EquipDef, b: EquipDef) -> bool:
		var by_a: int = rarity_order.get(a.rarity, 0)
		var by_b: int = rarity_order.get(b.rarity, 0)
		return String(a.id) < String(b.id) if by_a == by_b else by_a > by_b)
	return out


## slot key -> item id of everything the hero wears now (saved choice, else the start loadout).
static func worn(equipment: Dictionary[StringName, StringName], start: LoadoutDef) -> Dictionary[StringName, StringName]:
	var out: Dictionary[StringName, StringName] = {}
	for part: StringName in parts_for(start.hero):
		out[Inventory.slot_key(start.hero, part)] = Loadout.worn(equipment, start, part)
	return out


## The hero's fighter with the staged items on (a new CombatantDef; base is never touched).
static func fighter(
		base: CombatantDef, hero: StringName, staged: Dictionary[StringName, StringName],
		items: Dictionary[StringName, EquipDef], perks: Dictionary[StringName, PerkDef]) -> CombatantDef:
	var state := GearState.new()
	state.base = base
	state.perks = perks
	state.hilt = items.get(staged.get(Inventory.slot_key(hero, &"hilt"), &"")) as HiltDef
	state.blade = items.get(staged.get(Inventory.slot_key(hero, &"blade"), &"")) as BladeDef
	state.prosthetic = items.get(staged.get(Inventory.slot_key(hero, &"prosthetic"), &"")) as ProstheticDef
	state.frame = items.get(staged.get(Inventory.slot_key(hero, &"frame"), &"")) as PistolDef
	state.barrel = items.get(staged.get(Inventory.slot_key(hero, &"barrel"), &"")) as PistolDef
	state.accessory = items.get(staged.get(Inventory.slot_key(hero, &"accessory"), &"")) as AccessoryDef
	return Gear.build_hero(hero, state)


## Writes every staged slot into equipment through Inventory.equip; returns what was refused (empty = all ok).
static func apply(
		equipment: Dictionary[StringName, StringName], owned: Array[StringName],
		staged: Dictionary[StringName, StringName], items: Dictionary[StringName, EquipDef]) -> PackedStringArray:
	var problems := PackedStringArray()
	for slot: StringName in staged:
		if staged[slot] == &"":
			continue
		var problem: String = Inventory.equip(equipment, owned, slot, items.get(staged[slot]) as EquipDef)
		if not problem.is_empty():
			problems.append(problem)
	return problems
