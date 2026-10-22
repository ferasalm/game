class_name EquipmentOptions
extends RefCounted
## Pure rules of the equipment screen: which slots a hero has, which OWNED items fit a slot (best rarity first),
## which items a hero wears now, the fighter built from a staged set of items, and writing a staged set into
## the saved equipment through Inventory.equip. Items and perks are passed in (looked up by the view).


## "zayd" -> hilt, blade, prosthetic; every other hero -> prosthetic only.
static func parts_for(hero: StringName) -> Array[StringName]:
	if hero == Jambiyah.WIELDER:
		return [&"hilt", &"blade", &"prosthetic"]
	return [&"prosthetic"]


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
		return a.id < b.id if by_a == by_b else by_a > by_b)
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
	var hilt := items.get(staged.get(Inventory.slot_key(hero, &"hilt"), &"")) as HiltDef
	var blade := items.get(staged.get(Inventory.slot_key(hero, &"blade"), &"")) as BladeDef
	var prosthetic := items.get(staged.get(Inventory.slot_key(hero, &"prosthetic"), &"")) as ProstheticDef
	return Gear.build(base, hilt, blade, prosthetic, perks)


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
