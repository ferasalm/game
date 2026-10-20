extends SceneTree
## Balance harness: 1,000 seeded battles per hilt + blade pairing with BattleAI playing both sides, one table.
## Run: GODOT_TIMEOUT=900 tools/run_godot.sh -s res://features/combat/harness/balance.gd [-- <battles>]
## (default 1000 per pairing; tune content/*.json, not code).

var _battles: int = 1000


func _process(_delta: float) -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_battles = maxi(1, args[0].to_int())
	var db: Node = load("res://core/content_db.gd").new()
	var problems: PackedStringArray = db.call("load_all")
	if not problems.is_empty():
		push_error("content problems: " + "\n".join(problems))
	var loader: BattleLoader = BattleLoader.from_db(db)
	db.free()
	print("pairing                     win %   mean secs   interrupts/battle")
	for hilt_id: StringName in loader.hilts:
		for blade_id: StringName in loader.blades:
			print(_row(loader, hilt_id, blade_id))
	quit(0)
	return true


func _row(loader: BattleLoader, hilt_id: StringName, blade_id: StringName) -> String:
	var wins: int = 0
	var ticks: int = 0
	var interrupts: int = 0
	for battle_seed: int in range(1, _battles + 1):
		var sim: BattleSim = loader.make_sim(hilt_id, blade_id, battle_seed)
		for event: TimelineEvent in BattleLoader.autoplay(sim):
			if event.kind == &"interrupted":
				interrupts += 1
		wins += 1 if sim.result == &"victory" else 0
		ticks += sim.ticks
	return "%-26s %5.1f   %9.1f   %17.2f" % [
		"%s + %s" % [hilt_id, blade_id], 100.0 * wins / _battles,
		float(ticks) / _battles / Timeline.TICKS_PER_SECOND, float(interrupts) / _battles]
