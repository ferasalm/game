extends TestCase
## Tests for TitleOverlay: Continue loads the newest slot, Load opens the slot picker, and New Game.


func _dir() -> String:
	return SaveService.default_dir.path_join("title_test")


func _clean() -> void:
	Screens.clear()
	Router.save_dir = _dir()
	Router.scene_reloader = func() -> void: pass
	var service := SaveService.new(_dir())
	for s: int in range(1, 4):
		service.delete(s)


func _data(money: int) -> Dictionary:
	return {"version": 4, "money": money, "play_seconds": 10.0, "place": {"area": "souq_rooftops", "save_point": "sabil"}}


func test_title_overlay_buttons_disabled_when_no_saves() -> void:
	_clean()
	var overlay := TitleOverlay.new()
	tree.root.add_child(overlay)
	check(overlay.button_continue().disabled, "Continue is disabled with no saves")
	check(overlay.button_load().disabled, "Load is disabled with no saves")
	check(not overlay.button_new_game().disabled, "New Game is enabled")
	overlay.free()
	_clean()


func test_title_overlay_continue_picks_newest_slot() -> void:
	_clean()
	var service := SaveService.new(_dir())
	service.write(1, _data(10))
	service.write(2, _data(20))
	var overlay := TitleOverlay.new()
	tree.root.add_child(overlay)
	check(not overlay.button_continue().disabled, "Continue is enabled")
	overlay.button_continue().pressed.emit()
	check_eq(Router.last_slot, 2, "Continue loaded the newest slot (slot 2)")
	check_eq(GameState.money, 20, "GameState has slot 2 money")
	overlay.free()
	_clean()


func test_title_overlay_load_opens_picker() -> void:
	_clean()
	var service := SaveService.new(_dir())
	service.write(1, _data(10))
	var overlay := TitleOverlay.new()
	tree.root.add_child(overlay)
	overlay.button_load().pressed.emit()
	check(Screens.is_open_id(Screens.SLOT_PICKER_ID), "slot picker is open")
	var picker: SlotPickerScreen = Screens.top() as SlotPickerScreen
	check_eq(picker.mode, SlotPickerScreen.MODE_LOAD, "picker opened in load mode")
	_clean()
	overlay.free()
