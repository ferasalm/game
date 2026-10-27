extends TestCase
## The loadout fallback: a hero wears the saved item per slot, else the start loadout.


func _start() -> LoadoutDef:
	return ContentDB.get_def("loadout", &"rydan_start") as LoadoutDef


func test_start_loadout_is_the_grandfather_hilt_and_a_rustwire_blade() -> void:
	check_eq(_start().hilt, &"grandfather_hilt", "start hilt")
	check_eq(_start().blade, &"rustwire_blade", "start blade")
	check_eq(_start().prosthetic, &"salvage_arm", "start prosthetic")


func test_loadout_falls_back_per_slot() -> void:
	var none: Dictionary[StringName, StringName] = {}
	var start: Array[StringName] = [&"grandfather_hilt", &"rustwire_blade"]
	check_eq(Loadout.current(none, _start()), start, "empty: start pair")
	var blade_only: Dictionary[StringName, StringName] = {&"rydan.blade": &"broad_blade"}
	check_eq(Loadout.current(blade_only, _start()), [&"grandfather_hilt", &"broad_blade"] as Array[StringName], "missing hilt")
	var blank: Dictionary[StringName, StringName] = {&"rydan.hilt": &"", &"rydan.blade": &"broad_blade"}
	check_eq(Loadout.current(blank, _start()), [&"grandfather_hilt", &"broad_blade"] as Array[StringName], "empty hilt")
	var both: Dictionary[StringName, StringName] = {&"rydan.hilt": &"anvil_hilt", &"rydan.blade": &"broad_blade"}
	check_eq(Loadout.current(both, _start()), [&"anvil_hilt", &"broad_blade"] as Array[StringName], "saved pair")
