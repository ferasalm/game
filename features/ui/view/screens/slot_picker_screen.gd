class_name SlotPickerScreen
extends UiScreen
## Slot picker screen: title (560,60), 3 slot rows (440,180), details (1380,180), buttons (500,880).

signal slot_chosen(slot: int)

const ID: StringName = &"slot_picker"
const MODE_SAVE: StringName = &"save"
const MODE_LOAD: StringName = &"load"

var mode: StringName = MODE_SAVE
var chosen_slot: int = 0
var _focused_slot: int = 1
var _slot_rows: Array[SlotRow] = []
var _buttons: Array[Button] = []
var _loader: Callable = Callable()

var _title_panel: UiPanel
var _rows_box: VBoxContainer
var _detail: SlotDetail
var _action_bar: HBoxContainer
var _save_btn: Button
var _delete_btn: Button
var _back_btn: Button


func _init() -> void:
	super()
	backdrop_id = &"save"
	layer_id = UiLayers.SCREEN


func build(args: Dictionary) -> void:
	mode = args.get("mode", MODE_SAVE)
	_loader = args.get("loader", Router.load_slot)
	var is_save: bool = mode == MODE_SAVE
	prompts = [
		{"key": "accept", "text": "SLOT_PROMPT_SAVE" if is_save else "SLOT_PROMPT_LOAD"},
		{"key": "back", "text": "PAUSE_NO"}
	]
	var style: UiStyleDef = Ui.style()

	var title_en: String = Ui.text("SLOT_TITLE_SAVE" if is_save else "SLOT_TITLE_LOAD")
	var title_musnad: String = Ui.text("SLOT_TITLE_SAVE_MUSNAD" if is_save else "SLOT_TITLE_LOAD_MUSNAD")
	_title_panel = Ui.panel(title_en, title_musnad)
	_title_panel.position = Vector2(560, 60)
	_title_panel.size = Vector2(800, 90)
	_title_panel.custom_minimum_size = Vector2(800, 90)
	add_child(_title_panel)

	_rows_box = VBoxContainer.new()
	_rows_box.position = Vector2(440, 180)
	_rows_box.size = Vector2(900, 620)
	_rows_box.custom_minimum_size = Vector2(900, 620)
	_rows_box.add_theme_constant_override("separation", style.size(&"s_gap"))
	add_child(_rows_box)

	_detail = SlotDetail.new()
	_detail.position = Vector2(1380, 180)
	_detail.size = Vector2(460, 620)
	add_child(_detail)

	_build_action_bar(is_save)
	_build_slot_list()


func focus_default() -> void:
	if not is_inside_tree():
		return
	for button: Button in _buttons:
		if not button.disabled:
			button.grab_focus()
			return


func on_back() -> bool:
	chosen_slot = 0
	close(0)
	return true


func buttons() -> Array[Button]:
	return _buttons


func slot_rows() -> Array[SlotRow]:
	return _slot_rows


func title_panel() -> UiPanel:
	return _title_panel


func rows_container() -> VBoxContainer:
	return _rows_box


func detail_panel() -> SlotDetail:
	return _detail


func action_bar() -> HBoxContainer:
	return _action_bar


func _build_action_bar(is_save: bool) -> void:
	var style: UiStyleDef = Ui.style()
	_action_bar = HBoxContainer.new()
	_action_bar.position = Vector2(500, 880)
	_action_bar.size = Vector2(860, 72)
	_action_bar.add_theme_constant_override("separation", style.size(&"s_pad"))
	add_child(_action_bar)

	_save_btn = _make_action_button(Ui.text("SLOT_PROMPT_SAVE" if is_save else "SLOT_PROMPT_LOAD"))
	_save_btn.pressed.connect(_on_action_primary)
	_action_bar.add_child(_save_btn)
	if not is_save:
		_save_btn.visible = false

	_delete_btn = _make_action_button(Ui.text("SLOT_DELETE_BUTTON"))
	_delete_btn.pressed.connect(_on_delete_pressed)
	_action_bar.add_child(_delete_btn)

	_back_btn = _make_action_button(Ui.text("SLOT_BACK_BUTTON"))
	_back_btn.pressed.connect(on_back)
	_action_bar.add_child(_back_btn)


func _make_action_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(280, 72)
	UiBoxes.apply_pill_button(btn, Ui.style())
	return btn


func _build_slot_list() -> void:
	for old: Node in _rows_box.get_children():
		old.queue_free()
	_slot_rows.clear()
	_buttons.clear()

	var count: int = SaveService.slot_count()
	var service := SaveService.new(Router.save_dir)
	for slot: int in range(1, count + 1):
		var has_data: bool = service.exists(slot)
		var summary: Dictionary = service.summary(slot) if has_data else {}
		var row := SlotRow.new().setup(slot, has_data, summary, service, mode)
		row.pressed.connect(_on_slot_pressed.bind(slot))
		row.focus_entered.connect(_on_slot_focused.bind(slot, has_data, summary, service))
		_rows_box.add_child(row)
		_slot_rows.append(row)
		_buttons.append(row)

	if not _slot_rows.is_empty():
		var first_has_data: bool = service.exists(1)
		_detail.show_slot(1, first_has_data, service.summary(1) if first_has_data else {}, service)


func _on_slot_focused(slot: int, has_data: bool, summary: Dictionary, service: SaveService) -> void:
	_focused_slot = slot
	_detail.show_slot(slot, has_data, summary, service)


func _on_action_primary() -> void:
	_on_slot_pressed(_focused_slot)


func _on_delete_pressed() -> void:
	var service := SaveService.new(Router.save_dir)
	if not service.exists(_focused_slot):
		return
	var yes: bool = await Ui.confirm("SLOT_TITLE_SAVE", "SLOT_CONFIRM_DELETE", false)
	if yes:
		service.delete(_focused_slot)
		_build_slot_list()


func _on_slot_pressed(slot: int) -> void:
	_focused_slot = slot
	var service := SaveService.new(Router.save_dir)
	if mode == MODE_SAVE:
		if Router.has_save(slot):
			var yes: bool = await Ui.confirm("SLOT_TITLE_SAVE", "SLOT_CONFIRM_OVERWRITE", false)
			if not yes:
				return
		chosen_slot = slot
		slot_chosen.emit(slot)
		close(slot)
	else:
		chosen_slot = slot
		slot_chosen.emit(slot)
		if _loader.is_valid():
			_loader.call(slot)
		close(slot)
