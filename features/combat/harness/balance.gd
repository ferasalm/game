extends SceneTree
## Balance harness: seeded battles per gear pairing with BattleAI playing both sides, one table.
## Run: GODOT_TIMEOUT=1800 tools/run_godot.sh -s res://features/combat/harness/balance.gd -- [battles] [all|obtainable] [name filter] [encounter id] [herbs, e.g. pink_herb=2,white_herb=1]
## Default 1000 battles per row and only the items the prototype hands out; "all" adds every item in the data.
## Rows: Zayd's hilt x blade x prosthetic (Bilqis in her start rig), then Bilqis's prosthetics (Zayd in his
## start gear). Tune content/*.json, not code.

var _battles: int = 1000
var _all: bool = false
var _filter: String = ""
var _encounter: StringName = &"rooftop_patrol"
var _bag: Dictionary = {}
var _loader: BattleLoader


func _process(_delta: float) -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_battles = maxi(1, args[0].to_int())
	_all = args.size() > 1 and args[1] == "all"
	_filter = args[2] if args.size() > 2 else ""
	if args.size() > 3:
		_encounter = StringName(args[3])
	if args.size() > 4:
		_bag = _parse_bag(args[4])
	var db: Node = load("res://core/content_db.gd").new()
	var problems: PackedStringArray = db.call("load_all")
	if not problems.is_empty():
		push_error("content problems: " + "\n".join(problems))
	_loader = BattleLoader.from_db(db, _encounter)
	_loader.start_bag = _bag
	db.free()
	print("%-52s win %%   secs   interrupts  heals  herbs" % "zayd gear (bilqis in her start rig)")
	for hilt_id: StringName in _pool(_loader.hilts.keys(), [&"grandfather_hilt", &"swift_hilt", &"anvil_hilt"]):
		for blade_id: StringName in _pool(_loader.blades.keys(), [&"rustwire_blade", &"keen_blade"]):
			for arm_id: StringName in _pool(_zayd_arms(), [&"salvage_arm", &"arc_arm"]):
				print(_row("%s + %s + %s" % [hilt_id, blade_id, arm_id], hilt_id, blade_id, arm_id, &"wrist_rig"))
	print("%-52s win %%   secs   interrupts  heals  herbs" % "bilqis rig (zayd in his start gear)")
	for rig_id: StringName in _pool(_bilqis_rigs(), [&"wrist_rig", &"lens_array"]):
		print(_row("bilqis: %s" % rig_id, &"grandfather_hilt", &"rustwire_blade", &"salvage_arm", rig_id))
	quit(0)
	return true


## The obtainable ids, or every id in "all" mode.
func _pool(every: Array, obtainable: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	var source: Array = every if _all else obtainable
	for item_id: Variant in source:
		out.append(item_id as StringName)
	return out


func _zayd_arms() -> Array[StringName]:
	return _worn_by(&"zayd")


func _bilqis_rigs() -> Array[StringName]:
	return _worn_by(&"bilqis")


func _worn_by(hero_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for prosthetic: ProstheticDef in _loader.prosthetics.values():
		if prosthetic.wearer == hero_id:
			out.append(prosthetic.id)
	return out


func _row(label: String, hilt_id: StringName, blade_id: StringName, arm_id: StringName, rig_id: StringName) -> String:
	if not _filter.is_empty() and not label.contains(_filter):
		return "(skipped) " + label
	var wins: int = 0
	var ticks: int = 0
	var interrupts: int = 0
	var heals: int = 0
	var herbs: int = 0
	for battle_seed: int in range(1, _battles + 1):
		var sim: BattleSim = _loader.make_sim(hilt_id, blade_id, battle_seed, 0, arm_id, rig_id)
		for event: TimelineEvent in BattleLoader.autoplay(sim, not _bag.is_empty()):
			interrupts += 1 if event.kind == &"interrupted" else 0
			heals += 1 if event.kind == &"healed" and event.detail != &"regen" else 0
			herbs += 1 if event.kind == &"item_used" else 0
		wins += 1 if sim.result == &"victory" else 0
		ticks += sim.ticks
	return "%-52s %5.1f  %5.1f  %9.2f  %5.2f  %5.2f" % [
		label, 100.0 * wins / _battles, float(ticks) / _battles / Timeline.TICKS_PER_SECOND,
		float(interrupts) / _battles, float(heals) / _battles, float(herbs) / _battles]


## "pink_herb=2,white_herb=1" -> {pink_herb: 2, white_herb: 1}. With herbs the heroes use ItemPolicy.
func _parse_bag(text: String) -> Dictionary:
	var out: Dictionary = {}
	for pair: String in text.split(","):
		var parts: PackedStringArray = pair.split("=")
		if parts.size() == 2:
			out[StringName(parts[0])] = parts[1].to_int()
	return out
