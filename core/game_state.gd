extends Node
## Everything a save file holds (autoload GameState). Plain data only: nodes read and write it, never own it.
## to_dict()/from_dict() are the save format (SaveCodec migrates old versions).

var flags: Dictionary[StringName, bool] = {}
## Worn gear per hero and part: &"zayd.hilt", &"zayd.armor", etc. -> content ids.
var equipment: Dictionary[StringName, StringName] = {}
## Unique items the party owns (hilts, blades, prosthetics, armors, stones), each id at most once.
var inventory: Array[StringName] = []
var counters: Dictionary[StringName, int] = {}
var party: Array[StringName] = []
var area_id: StringName = &""
var save_point: StringName = &""
var money: int = 0
var bag: Dictionary[StringName, int] = {}
var vitals: Dictionary[StringName, Dictionary] = {}
var cleared_patrols: Array[StringName] = []
var play_seconds: float = 0.0
var load_warnings: PackedStringArray = PackedStringArray()
var xp: Dictionary[StringName, int] = {}
var sockets: Dictionary[StringName, Array] = {}
var upgrades: Dictionary[StringName, int] = {}
var materials: Dictionary[StringName, int] = {}


func reset() -> void:
	flags.clear()
	equipment.clear()
	inventory.clear()
	counters.clear()
	party.clear()
	area_id = &""
	save_point = &""
	money = 0
	bag.clear()
	vitals.clear()
	cleared_patrols.clear()
	play_seconds = 0.0
	xp.clear()
	sockets.clear()
	upgrades.clear()
	materials.clear()


## A fresh game: everything reset, starting equipment, stones, money, bag, and party.
func start_new() -> void:
	reset()
	var rules := ContentDB.get_def("economy_rules", &"default") as EconomyRulesDef
	if rules != null:
		money = rules.start_money
		bag = rules.start_bag.duplicate()
		party = rules.start_party.duplicate()
	equipment[&"zayd.armor"] = &"courier_jacket"
	equipment[&"bilqis.armor"] = &"rig_shawl"
	for item_id: StringName in [&"courier_jacket", &"rig_shawl", &"aqiq_red"]:
		if not inventory.has(item_id):
			inventory.append(item_id)
	sockets[&"grandfather_hilt"] = [&"aqiq_red"]
	for hero: StringName in party:
		xp[hero] = 0


func to_dict() -> Dictionary:
	return {
		"version": SaveCodec.VERSION,
		"flags": flags.duplicate(),
		"equipment": equipment.duplicate(),
		"inventory": inventory.duplicate(),
		"counters": counters.duplicate(),
		"party": party.duplicate(),
		"place": {"area": String(area_id), "save_point": String(save_point)},
		"money": money,
		"bag": bag.duplicate(),
		"vitals": vitals.duplicate(true),
		"cleared_patrols": cleared_patrols.duplicate(),
		"play_seconds": play_seconds,
		"xp": xp.duplicate(),
		"sockets": sockets.duplicate(true),
		"upgrades": upgrades.duplicate(),
		"materials": materials.duplicate(),
	}


func from_dict(raw: Dictionary) -> String:
	var migrated: Dictionary = SaveCodec.migrate(raw)
	if not bool(migrated["ok"]):
		return str(migrated["error"])
	var data: Dictionary = migrated["data"]
	load_warnings = SaveCodec.sanitize(data, _known_ids())
	for warning: String in load_warnings:
		push_warning("GameState: " + warning)
	reset()
	_read_items(data)
	_read_numbers(data)
	return ""


func holdings() -> Holdings:
	var held := Holdings.new()
	held.money = money
	held.bag = Bag.from_counts(bag)
	held.inventory = inventory
	held.flags = flags
	return held


func take(held: Holdings) -> void:
	money = held.money
	bag = held.bag.snapshot()


func set_vitals(src: Dictionary) -> void:
	vitals.clear()
	for hero: Variant in src:
		vitals[StringName(str(hero))] = (src[hero] as Dictionary).duplicate()


func set_bag(src: Dictionary) -> void:
	bag.clear()
	for item_id: Variant in src:
		if int(src[item_id]) > 0:
			bag[StringName(str(item_id))] = int(src[item_id])


func summary() -> Dictionary:
	return SaveCodec.summary(to_dict())


func _read_items(data: Dictionary) -> void:
	for slot: Variant in (data.get("equipment", {}) as Dictionary):
		equipment[StringName(str(slot))] = StringName(str(data["equipment"][slot]))
	for item: Variant in (data.get("inventory", []) as Array):
		inventory.append(StringName(str(item)))
	for key: Variant in (data.get("flags", {}) as Dictionary):
		flags[StringName(str(key))] = bool(data["flags"][key])
	for key: Variant in (data.get("counters", {}) as Dictionary):
		counters[StringName(str(key))] = int(data["counters"][key])
	for member: Variant in (data.get("party", []) as Array):
		party.append(StringName(str(member)))
	for hilt: Variant in (data.get("sockets", {}) as Dictionary):
		var list: Array = []
		for s: Variant in (data["sockets"][hilt] as Array):
			list.append(StringName(str(s)))
		sockets[StringName(str(hilt))] = list


func _read_numbers(data: Dictionary) -> void:
	var place: Dictionary = data.get("place", {})
	area_id = StringName(str(place.get("area", "")))
	save_point = StringName(str(place.get("save_point", "")))
	money = maxi(0, int(data.get("money", 0)))
	for key: Variant in (data.get("bag", {}) as Dictionary):
		if int(data["bag"][key]) > 0:
			bag[StringName(str(key))] = int(data["bag"][key])
	for hero: Variant in (data.get("vitals", {}) as Dictionary):
		var entry: Dictionary = data["vitals"][hero]
		var kept: Dictionary = {}
		for field: String in ["hp", "sp"]:
			if entry.has(field):
				kept[field] = maxi(0, int(entry[field]))
		vitals[StringName(str(hero))] = kept
	for encounter: Variant in (data.get("cleared_patrols", []) as Array):
		cleared_patrols.append(StringName(str(encounter)))
	play_seconds = float(data.get("play_seconds", 0.0))
	for hero: Variant in (data.get("xp", {}) as Dictionary):
		xp[StringName(str(hero))] = int(data["xp"][hero])
	for item: Variant in (data.get("upgrades", {}) as Dictionary):
		upgrades[StringName(str(item))] = int(data["upgrades"][item])
	for mat: Variant in (data.get("materials", {}) as Dictionary):
		materials[StringName(str(mat))] = int(data["materials"][mat])


func _known_ids() -> Dictionary:
	var items: Array = []
	for kind: String in ContentDB.ITEM_KINDS:
		items.append_array(ContentDB.ids(kind))
	items.append_array(ContentDB.ids("stone"))
	return {
		"item": items, "consumable": ContentDB.ids("consumable"), "hero": ContentDB.ids("combatant"),
		"encounter": ContentDB.ids("encounter"),
	}
