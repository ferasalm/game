class_name PauseMenu
extends UiScreen
## Pause menu screen: command panel (80,80), info box (80,880), party panel (540,80), prompt strip (0,1020).

var _buttons: Dictionary[StringName, Button] = {}
var _entry_ids: Array[StringName] = []
var _cmd_panel: UiPanel
var _info_box: PanelContainer
var _party_panel: UiPanel
var _party: PauseParty


func _init() -> void:
	super()
	backdrop_id = &"pause"
	layer_id = UiLayers.PAUSE
	prompts = [{"key": "accept", "text": "PAUSE_PROMPT_SELECT"}, {"key": "back", "text": "PAUSE_PROMPT_RESUME"}]


func build(_args: Dictionary) -> void:
	var style: UiStyleDef = Ui.style()

	_cmd_panel = Ui.panel()
	_cmd_panel.position = Vector2(80, 80)
	_cmd_panel.size = Vector2(420, 760)
	_cmd_panel.custom_minimum_size = Vector2(420, 760)
	add_child(_cmd_panel)

	var title_plate: PanelContainer = Ui.title_plate(Ui.text("PAUSE_HEADING"), Ui.text("PAUSE_HEADING_MUSNAD"))
	_cmd_panel.body.add_child(title_plate)
	_cmd_panel.body.add_child(Ui.divider())

	_entry_ids = PauseLogic.entries(Screens.has_screen(PauseLogic.ITEMS), Screens.has_screen(PauseLogic.EQUIPMENT),
			Router.has_any_save(), Screens.has_screen(PauseLogic.MAP))
	for i: int in _entry_ids.size():
		var id: StringName = _entry_ids[i]
		_buttons[id] = _add_entry(_cmd_panel, id, i + 1)

	_info_box = PanelContainer.new()
	_info_box.name = "InfoBox"
	_info_box.position = Vector2(80, 880)
	_info_box.size = Vector2(420, 100)
	_info_box.custom_minimum_size = Vector2(420, 100)
	_info_box.add_theme_stylebox_override("panel", UiBoxes.panel(style, &"glass"))
	add_child(_info_box)
	_build_info_box(_info_box)

	_party = PauseParty.new()
	_party.fill()
	var party_count: int = _party.rows().size()
	var row_h: int = 200
	var pad_y: int = style.size(&"s_pad")
	var content_h: int = party_count * row_h + maxi(0, party_count - 1) * pad_y
	var margin_y: int = int(style.size(&"s_frame_cell") - style.size(&"s_frame_gap")) * 2
	var panel_h: int = content_h + margin_y

	_party_panel = Ui.panel()
	_party_panel.position = Vector2(540, 80)
	_party_panel.size = Vector2(1300, panel_h)
	_party_panel.custom_minimum_size = Vector2(1300, panel_h)
	add_child(_party_panel)
	_party_panel.body.add_child(_party)


func focus_default() -> void:
	if not is_inside_tree():
		return
	if _buttons.has(PauseLogic.RESUME):
		_buttons[PauseLogic.RESUME].grab_focus()


func on_back() -> bool:
	close()
	return true


func on_menu() -> bool:
	close()
	return true


func entry_ids() -> Array[StringName]:
	return _entry_ids


func button_of(id: StringName) -> Button:
	return _buttons.get(id)


func cmd_panel() -> UiPanel:
	return _cmd_panel


func info_box() -> PanelContainer:
	return _info_box


func party_panel() -> UiPanel:
	return _party_panel


func party() -> PauseParty:
	return _party


func activate(id: StringName) -> void:
	var question: String = PauseLogic.confirm_key(id)
	if question.is_empty():
		_run(id)
		return
	var yes: bool = await Ui.confirm(PauseLogic.label_key(id), question, false)
	if yes:
		_run(id)


func _run(id: StringName) -> void:
	match id:
		PauseLogic.RESUME:
			close()
		PauseLogic.ITEMS, PauseLogic.EQUIPMENT, PauseLogic.MAP:
			Screens.open(id)
		PauseLogic.LOAD:
			Screens.open(Screens.SLOT_PICKER_ID, {"mode": SlotPickerScreen.MODE_LOAD})
		PauseLogic.LOAD_LAST:
			close()
			var problem: String = Router.load_slot(Router.last_slot)
			if not problem.is_empty():
				push_warning("PauseMenu: load failed: " + problem)
		PauseLogic.RESTART:
			close()
			Router.new_game()
		PauseLogic.UNSTUCK:
			close()
			Router.unstuck()
		PauseLogic.TITLE:
			close()
			Router.go_to_title()
		PauseLogic.QUIT:
			Router.quit_game()


func _add_entry(menu: UiPanel, id: StringName, index: int) -> Button:
	var button := Button.new()
	button.text = "%d  %s" % [index, Ui.text(PauseLogic.label_key(id))]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = Ui.style().size(&"s_list_row_h")
	button.pressed.connect(activate.bind(id))
	button.mouse_entered.connect(button.grab_focus)
	sweep_on_focus(button)
	menu.body.add_child(button)
	return button


func _build_info_box(box: PanelContainer) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	box.add_child(col)
	var area := ContentDB.get_def("area", GameState.area_id) as AreaDef
	var place: String = Ui.text(area.name_key) if area != null else "Souq al-Milh Rooftops"
	col.add_child(Ui.label("%s: %s" % [Ui.text("PAUSE_AREA"), place], &"SmallLabel"))
	var row := HBoxContainer.new()
	var money: MoneyCounter = Ui.money_counter(true)
	money.set_amount(PauseLogic.money_of(GameState.get(&"money")), false)
	row.add_child(money)
	var time_lbl := Ui.label("%s: %s" % [Ui.text("PAUSE_TIME"), PauseLogic.clock(GameState.get(&"play_seconds"))], &"SmallLabel")
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(time_lbl)
	col.add_child(row)
