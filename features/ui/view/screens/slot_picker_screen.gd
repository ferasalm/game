class_name SlotPickerScreen
extends UiScreen
## Slot picker screen: one row per save slot showing summary or Empty.
## Save mode confirms overwrite for used slots; Load mode greys empty slots.

signal slot_chosen(slot: int)

const ID: StringName = &"slot_picker"
const MODE_SAVE: StringName = &"save"
const MODE_LOAD: StringName = &"load"

var mode: StringName = MODE_SAVE
var chosen_slot: int = 0
var _buttons: Array[Button] = []
var _loader: Callable = Callable()


func _init() -> void:
	super()
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
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var title_en: String = Ui.text("SLOT_TITLE_SAVE" if is_save else "SLOT_TITLE_LOAD")
	var title_musnad: String = Ui.text("SLOT_TITLE_SAVE_MUSNAD" if is_save else "SLOT_TITLE_LOAD_MUSNAD")
	var panel: UiPanel = Ui.panel(title_en, title_musnad)
	panel.custom_minimum_size = Vector2(int(style.size(&"s_confirm_w") * 1.5), 0)
	centre.add_child(panel)
	_build_slot_list(panel.body)


func focus_default() -> void:
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


func _build_slot_list(parent: Control) -> void:
	_buttons.clear()
	var count: int = SaveService.slot_count()
	var service := SaveService.new(Router.save_dir)
	for slot: int in range(1, count + 1):
		var has_data: bool = service.exists(slot)
		var summary: Dictionary = service.summary(slot) if has_data else {}
		var button := Button.new()
		button.text = _row_text(slot, summary)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = Ui.style().size(&"s_list_row_h")
		if mode == MODE_LOAD and not has_data:
			button.disabled = true
		button.pressed.connect(_on_slot_pressed.bind(slot))
		button.mouse_entered.connect(_hover.bind(button))
		sweep_on_focus(button)
		parent.add_child(button)
		_buttons.append(button)


func _on_slot_pressed(slot: int) -> void:
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


func _hover(button: Button) -> void:
	if not button.disabled:
		button.grab_focus()


func _row_text(slot: int, summary: Dictionary) -> String:
	if summary.is_empty():
		return Ui.text("SLOT_ROW_EMPTY") % slot
	var area_id: StringName = StringName(str(summary.get("area", "")))
	var area_def := ContentDB.get_def("area", area_id) as AreaDef
	var place: String = Ui.text(area_def.name_key) if area_def != null else String(area_id)
	var time_text: String = PauseLogic.clock(summary.get("play_seconds", 0.0))
	return Ui.text("SLOT_ROW_USED") % [slot, place, time_text]
