class_name EquipmentData
extends RefCounted
## purpose: What the equipment screen needs from ContentDB, read once.

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


func worn_item(equipment: Dictionary, hero_name: StringName, part: StringName) -> EquipDef:
	if part == &"gemstones":
		var hilt_id: StringName = equipment.get(Inventory.slot_key(hero_name, &"hilt"), &"")
		var socks: Array = GameState.sockets.get(hilt_id, [])
		var s_id: StringName = StringName(str(socks[0])) if not socks.is_empty() else &""
		return ContentDB.get_def("stone", s_id) as EquipDef
	var key: StringName = Inventory.slot_key(hero_name, part)
	var id: StringName = equipment.get(key, &"")
	if id == &"" and starts.has(hero_name):
		id = Loadout.worn(equipment, starts[hero_name], part)
	return ContentDB.get_def("item", id) as EquipDef
