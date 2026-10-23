extends TestCase
## Slot picker tests: save mode, overwrite confirmation dialog, load mode, empty slots greyed, and back.


func _dir() -> String:
	return SaveService.default_dir.path_join("picker_test")


func _clean() -> void:
	Screens.clear()
	Router.save_dir = _dir()
	var service := SaveService.new(_dir())
	for s: int in range(1, 4):
		service.delete(s)


func _data() -> Dictionary:
	return {"version": 4, "money": 50, "play_seconds": 10.0, "place": {"area": "souq_rooftops", "save_point": "sabil"}}


func test_slot_picker_save_empty_slot() -> void:
	_clean()
	var screen: SlotPickerScreen = Screens.open(Screens.SLOT_PICKER_ID, {"mode": SlotPickerScreen.MODE_SAVE}) as SlotPickerScreen
	check(screen != null, "slot picker opened")
	check_eq(screen.buttons().size(), 3, "has 3 slots")
	screen.buttons()[0].pressed.emit()
	check(not Screens.top() is ConfirmDialog, "empty slot does not ask overwrite")
	check_eq(screen.chosen_slot, 1, "picked slot 1")
	check(not Screens.is_open(), "picker closed")
	_clean()


func test_slot_picker_overwrite_confirm() -> void:
	_clean()
	SaveService.new(_dir()).write(1, _data())
	var screen: SlotPickerScreen = Screens.open(Screens.SLOT_PICKER_ID, {"mode": SlotPickerScreen.MODE_SAVE}) as SlotPickerScreen
	screen.buttons()[0].pressed.emit()
	check(Screens.top() is ConfirmDialog, "used slot pops ConfirmDialog")
	var dialog: ConfirmDialog = Screens.top() as ConfirmDialog
	dialog.answer(false)
	check(Screens.top() == screen, "No keeps the picker open")
	screen.buttons()[0].pressed.emit()
	check(Screens.top() is ConfirmDialog, "pops ConfirmDialog again")
	dialog = Screens.top() as ConfirmDialog
	dialog.answer(true)
	check_eq(screen.chosen_slot, 1, "picked slot 1 after confirm")
	check(not Screens.is_open(), "picker closed after confirm")
	# Playtest 2026-10-23: the picker closed while the dialog still covered it, stayed frozen and never faded out.
	check(screen.process_mode != Node.PROCESS_MODE_DISABLED, "the closing picker is not left frozen (it fades and frees)")
	_clean()


func test_slot_picker_load_mode_loads_slot() -> void:
	_clean()
	SaveService.new(_dir()).write(2, _data())
	var loaded_slot: Array[int] = [0]
	var loader := func(slot: int) -> String:
		loaded_slot[0] = slot
		return ""
	var screen: SlotPickerScreen = Screens.open(Screens.SLOT_PICKER_ID, {
		"mode": SlotPickerScreen.MODE_LOAD,
		"loader": loader
	}) as SlotPickerScreen
	screen.buttons()[1].pressed.emit()
	check_eq(loaded_slot[0], 2, "loader called with slot 2")
	check_eq(screen.chosen_slot, 2, "chosen slot is 2")
	_clean()


func test_slot_picker_load_mode_greys_empty_slots() -> void:
	_clean()
	SaveService.new(_dir()).write(1, _data())
	var screen: SlotPickerScreen = Screens.open(Screens.SLOT_PICKER_ID, {"mode": SlotPickerScreen.MODE_LOAD}) as SlotPickerScreen
	check(not screen.buttons()[0].disabled, "slot 1 is enabled (has save)")
	check(screen.buttons()[1].disabled, "slot 2 is disabled (empty)")
	check(screen.buttons()[2].disabled, "slot 3 is disabled (empty)")
	_clean()


func test_slot_picker_back_closes() -> void:
	_clean()
	var screen: SlotPickerScreen = Screens.open(Screens.SLOT_PICKER_ID, {"mode": SlotPickerScreen.MODE_SAVE}) as SlotPickerScreen
	screen.on_back()
	check_eq(screen.chosen_slot, 0, "no slot chosen on back")
	check(not Screens.is_open(), "picker closed on back")
	_clean()
