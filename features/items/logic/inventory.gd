class_name Inventory
extends RefCounted
## Which unique items the party owns and whether a hero may wear one in a slot. Pure: the owned list lives
## in GameState.inventory and the worn gear in GameState.equipment (slot key "<hero>.<part>").


static func slot_key(hero: StringName, part: StringName) -> StringName:
	return StringName("%s.%s" % [hero, part])


static func has(owned: Array[StringName], item_id: StringName) -> bool:
	return owned.has(item_id)


## Adds a unique item; false (and no change) when it is already owned or the id is empty.
static func add(owned: Array[StringName], item_id: StringName) -> bool:
	if item_id == &"" or owned.has(item_id):
		return false
	owned.append(item_id)
	return true


## Adds each id not yet owned; returns the ones that were new, in order.
static func add_all(owned: Array[StringName], item_ids: Array[StringName]) -> Array[StringName]:
	var added: Array[StringName] = []
	for item_id: StringName in item_ids:
		if add(owned, item_id):
			added.append(item_id)
	return added


## "" when the hero may wear this item in this slot now; else why not. Hilts and blades fit only the
## jambiyah wielder; a prosthetic fits only its own wearer.
static func equip_problem(owned: Array[StringName], slot: StringName, item: EquipDef) -> String:
	if item == null:
		return "no such item"
	if not owned.has(item.id):
		return "'%s' is not owned" % item.id
	var parts: PackedStringArray = String(slot).split(".")
	if parts.size() != 2:
		return "'%s' is not a slot" % slot
	var hero := StringName(parts[0])
	match parts[1]:
		"hilt":
			return "" if item is HiltDef and hero == Jambiyah.WIELDER else "'%s' is not a hilt for %s" % [item.id, hero]
		"blade":
			return "" if item is BladeDef and hero == Jambiyah.WIELDER else "'%s' is not a blade for %s" % [item.id, hero]
		"prosthetic":
			var worn := item as ProstheticDef
			return "" if worn != null and worn.wearer == hero else "'%s' does not fit %s" % [item.id, hero]
	return "'%s' is not a slot" % slot


## Wears the item when allowed (equipment[slot] = item id). Returns "" or why it was refused.
static func equip(
		equipment: Dictionary[StringName, StringName], owned: Array[StringName], slot: StringName,
		item: EquipDef) -> String:
	var problem: String = equip_problem(owned, slot, item)
	if problem.is_empty():
		equipment[slot] = item.id
	return problem
