extends TestCase
## Tests for Sabil saving into the slot chosen via the slot picker.

const DT: float = 1.0 / 60.0


func _dir() -> String:
	return SaveService.default_dir.path_join("sabil_slots")


func _clean() -> void:
	Screens.clear()
	Router.save_dir = _dir()
	var service := SaveService.new(_dir())
	for s: int in range(1, 4):
		service.delete(s)


func _make() -> Rooftop:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	tree.root.add_child(rooftop)
	return rooftop


func test_sabil_saves_to_picked_slot() -> void:
	_clean()
	GameState.start_new()
	var rooftop: Rooftop = _make()
	GameState.set_vitals({&"zayd": {"hp": 5, "sp": 2}})
	GameState.cleared_patrols.append(&"patrol_pair")
	rooftop.reset_patrol()
	check(rooftop.sabil.drink(2), "drink into slot 2")
	check(Router.has_save(2), "slot 2 has save")
	check(not Router.has_save(1), "slot 1 is untouched")
	check_eq(Router.last_slot, 2, "Router.last_slot is 2")
	check(GameState.vitals.is_empty(), "vitals refilled")
	check(GameState.cleared_patrols.is_empty(), "patrols cleared")
	rooftop.free()
	_clean()


func test_sabil_screen_opens_picker_and_saves() -> void:
	_clean()
	GameState.start_new()
	var rooftop: Rooftop = _make()
	rooftop.sabil.open_screen()
	check(Screens.is_open_id(Screens.SABIL_ID), "sabil screen is open")
	var sabil_screen: SabilScreen = Screens.top() as SabilScreen
	sabil_screen.choose(SabilScreen.DRINK)
	check(Screens.is_open_id(Screens.SLOT_PICKER_ID), "slot picker opened in save mode")
	var picker: SlotPickerScreen = Screens.top() as SlotPickerScreen
	check_eq(picker.mode, SlotPickerScreen.MODE_SAVE, "picker is in save mode")
	picker.buttons()[1].pressed.emit()
	check(Router.has_save(2), "slot 2 was saved through picker")
	check_eq(Router.last_slot, 2, "Router.last_slot updated to 2")
	rooftop.free()
	_clean()
