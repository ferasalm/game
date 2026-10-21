class_name Chests
extends RefCounted
## Chest rules: opening gives the item once, and the opened state is a saved flag. Pure.


## The GameState flag that records the chest as opened.
static func flag(chest_id: StringName) -> StringName:
	return StringName("chest_opened_" + String(chest_id))


static func is_open(chest: ChestDef, flags: Dictionary[StringName, bool]) -> bool:
	return flags.get(flag(chest.id), false)


## Opens the chest. Returns the item newly given, or &"" when it was already opened or the item was already
## owned (the chest still counts as opened, so it never gives anything twice).
static func open(chest: ChestDef, owned: Array[StringName], flags: Dictionary[StringName, bool]) -> StringName:
	if is_open(chest, flags):
		return &""
	flags[flag(chest.id)] = true
	return chest.item if Inventory.add(owned, chest.item) else &""


static func at_place(chests: Array[ChestDef], place: StringName) -> Array[ChestDef]:
	var out: Array[ChestDef] = []
	for chest: ChestDef in chests:
		if chest.place == place:
			out.append(chest)
	return out
