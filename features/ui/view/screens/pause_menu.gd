class_name PauseMenu
extends UiScreen
## The pause screen (opened by Screens on the menu action while exploring): the entries on the left (Resume, Items,
## Equipment, Load last save or Restart, Unstuck, Title, Quit), the party on the right. Entries that discard
## progress ask first (ConfirmDialog, default No). Items and Equipment open their registered screens on top.

var _buttons: Dictionary[StringName, Button] = {}
var _entry_ids: Array[StringName] = []


func _init() -> void:
	super()
	layer_id = UiLayers.PAUSE
	prompts = [{"key": "accept", "text": "PAUSE_PROMPT_SELECT"}, {"key": "back", "text": "PAUSE_PROMPT_RESUME"}]


func build(_args: Dictionary) -> void:
	var style: UiStyleDef = Ui.style()
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", style.size(&"s_margin"))
	centre.add_child(row)
	var menu: UiPanel = Ui.panel(Ui.text("PAUSE_HEADING"), Ui.text("PAUSE_HEADING_MUSNAD"))
	menu.custom_minimum_size = Vector2(style.size(&"s_pause_w"), style.size(&"s_pause_h"))
	row.add_child(menu)
	_entry_ids = PauseLogic.entries(Screens.has_screen(PauseLogic.ITEMS), Screens.has_screen(PauseLogic.EQUIPMENT),
			Router.has_save(1))
	for id: StringName in _entry_ids:
		_buttons[id] = _add_entry(menu, id)
	var party_panel: UiPanel = Ui.panel(Ui.text("PAUSE_PARTY"))
	party_panel.custom_minimum_size = Vector2(style.size(&"s_party_w"), style.size(&"s_pause_h"))
	row.add_child(party_panel)
	var party := PauseParty.new()
	party_panel.body.add_child(party)
	party.fill()


func focus_default() -> void:
	if _buttons.has(PauseLogic.RESUME):
		_buttons[PauseLogic.RESUME].grab_focus()


func on_back() -> bool:
	close()
	return true


func on_menu() -> bool:
	close()
	return true


## The entry ids in display order (for tests and other screens).
func entry_ids() -> Array[StringName]:
	return _entry_ids


func button_of(id: StringName) -> Button:
	return _buttons.get(id)


## Runs an entry as if its button was pressed (the button calls this).
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
		PauseLogic.ITEMS, PauseLogic.EQUIPMENT:
			Screens.open(id)
		PauseLogic.LOAD_LAST:
			close()
			var problem: String = Router.load_slot(1)
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


func _add_entry(menu: UiPanel, id: StringName) -> Button:
	var button := Button.new()
	button.text = Ui.text(PauseLogic.label_key(id))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = Ui.style().size(&"s_list_row_h")
	button.pressed.connect(activate.bind(id))
	button.mouse_entered.connect(button.grab_focus)
	sweep_on_focus(button)
	menu.body.add_child(button)
	return button
