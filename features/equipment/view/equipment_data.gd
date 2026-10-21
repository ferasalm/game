class_name EquipmentData
extends RefCounted
## What the equipment screen needs from ContentDB, read once: every equippable by id, the perks, the rarity
## order, and each hero's start loadout (heroes in loadout order).

var items: Dictionary[StringName, EquipDef] = {}
var perks: Dictionary[StringName, PerkDef] = {}
var rarity_order: Dictionary[StringName, int] = {}
var starts: Dictionary[StringName, LoadoutDef] = {}
var heroes: Array[StringName] = []


func _init() -> void:
	for kind: String in ContentDB.ITEM_KINDS:
		for item_id: StringName in ContentDB.ids(kind):
			items[item_id] = ContentDB.get_def(kind, item_id) as EquipDef
	for perk_id: StringName in ContentDB.ids("perk"):
		perks[perk_id] = ContentDB.get_def("perk", perk_id) as PerkDef
	for rarity_id: StringName in ContentDB.ids("rarity"):
		rarity_order[rarity_id] = UiRarity.order(rarity_id)
	for loadout_id: StringName in ContentDB.ids("loadout"):
		var start := ContentDB.get_def("loadout", loadout_id) as LoadoutDef
		starts[start.hero] = start
		heroes.append(start.hero)


func all_items() -> Array[EquipDef]:
	var out: Array[EquipDef] = []
	out.assign(items.values())
	return out
