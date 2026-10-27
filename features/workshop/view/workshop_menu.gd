class_name WorkshopMenu
extends UiScreen
## purpose: Workshop screen (upgrades, hilt gemstones, crafting) with Neon sprite hologram and live stat comparison.

const ID: StringName = &"workshop"

var _tabs: WorkshopTabsBar
var _items_list: WorkshopItemsList
var _hologram: WorkshopHologram
var _sockets: WorkshopSocketsRow
var _preview: WorkshopPreviewPanel
var _mats_bar: WorkshopMaterialsBar
var _action_btn: Button
var _selected_id: StringName = &""
var _selected_slot: int = 0
var _is_open: bool = false


func _init() -> void:
	super()
	backdrop_id = ID
	prompts = [
		{"key": "accept", "text": "WORKSHOP_PROMPT_CONFIRM"},
		{"key": "action_x", "text": "WORKSHOP_PROMPT_REMOVE_STONE"},
		{"key": "back", "text": "WORKSHOP_PROMPT_BACK"},
		{"key": "tab", "text": "WORKSHOP_PROMPT_TAB"},
	]


func build(_args: Dictionary) -> void:
	_is_open = true
	_tabs = WorkshopTabsBar.new()
	add_child(_tabs)
	_items_list = WorkshopItemsList.new()
	_items_list.item_selected.connect(_on_item_selected)
	_items_list.item_activated.connect(_on_action_pressed)
	add_child(_items_list)
	_build_center()
	_build_bottom()
	_preview = WorkshopPreviewPanel.new()
	add_child(_preview)
	_tabs.tab_selected.connect(_on_tab_changed)
	_on_tab_changed(_tabs.current_tab)


func focus_default() -> void:
	if _items_list != null:
		_items_list.focus_first()


func is_open() -> bool:
	return _is_open and not is_closing()


func cancel() -> void:
	_is_open = false
	close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"tab_next"):
		_tabs.next_tab()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"tab_prev"):
		_tabs.prev_tab()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"action_x") or (event is InputEventKey and event.pressed and event.keycode == KEY_X):
		if _tabs.current_tab == WorkshopTabsBar.Tab.GEMSTONES:
			_remove_stone()
			get_viewport().set_input_as_handled()


func _build_center() -> void:
	var box := Control.new()
	box.position = Vector2(580.0, 140.0)
	box.custom_minimum_size = Vector2(760.0, 620.0)
	box.size = Vector2(760.0, 620.0)
	add_child(box)
	_hologram = WorkshopHologram.new()
	box.add_child(_hologram)
	_sockets = WorkshopSocketsRow.new()
	_sockets.position = Vector2(0.0, 480.0)
	_sockets.socket_selected.connect(_on_socket_selected)
	_sockets.socket_focused.connect(_on_socket_selected)
	box.add_child(_sockets)


func _build_bottom() -> void:
	var style: UiStyleDef = Ui.style()
	_mats_bar = WorkshopMaterialsBar.new()
	add_child(_mats_bar)
	_action_btn = Button.new()
	_action_btn.custom_minimum_size = Vector2(400.0, 80.0)
	_action_btn.size = Vector2(400.0, 80.0)
	_action_btn.position = Vector2(760.0, 920.0)
	_action_btn.add_theme_stylebox_override("normal", UiBoxes.panel(style, &"plate", style.colour(&"c_cyan")))
	_action_btn.add_theme_stylebox_override("hover", UiBoxes.panel(style, &"plate", style.colour(&"c_brass")))
	_action_btn.add_theme_stylebox_override("pressed", UiBoxes.panel(style, &"plate", style.colour(&"c_brass")))
	_action_btn.add_theme_stylebox_override("disabled", UiBoxes.panel(style, &"plate", style.colour(&"c_disabled")))
	_action_btn.add_theme_color_override("font_color", style.colour(&"c_brass"))
	_action_btn.add_theme_color_override("font_hover_color", style.colour(&"c_cyan"))
	_action_btn.add_theme_color_override("font_disabled_color", style.colour(&"c_disabled"))
	_action_btn.add_theme_font_size_override("font_size", style.size(&"s_font_title"))
	_action_btn.pressed.connect(_on_action_pressed)
	sweep_on_focus(_action_btn)
	add_child(_action_btn)


func _on_tab_changed(tab: int) -> void:
	_selected_id = &""
	_sockets.visible = (tab == WorkshopTabsBar.Tab.GEMSTONES)
	_items_list.populate(tab)
	_refresh_sockets()


func _on_item_selected(id_name: StringName) -> void:
	_selected_id = id_name
	_update_views()


func _on_socket_selected(slot: int) -> void:
	_selected_slot = slot
	_update_views()


func _update_views() -> void:
	match _tabs.current_tab:
		WorkshopTabsBar.Tab.UPGRADE:
			var data: Dictionary = WorkshopPresenter.preview_upgrade(_selected_id)
			var cost: Dictionary = data.get("cost", {})
			_mats_bar.update_requirements(cost.get("materials", {}), int(cost.get("riyal", 0)), bool(data.get("max", false)))
			var prob: StringName = data.get("prob", &"")
			_action_btn.disabled = (prob != &"")
			_action_btn.text = Ui.text(prob) if prob != &"" else Ui.text("WORKSHOP_BTN_UPGRADE")
			_preview.update_stats(data.get("now"), data.get("after"))
		WorkshopTabsBar.Tab.GEMSTONES:
			var data: Dictionary = WorkshopPresenter.preview_gemstone(_selected_id, _selected_slot)
			var fits: bool = bool(data.get("fits", false))
			_mats_bar.update_requirements({}, 0)
			_action_btn.disabled = not fits
			_action_btn.text = Ui.text("WORKSHOP_BTN_SET_STONE") if fits else Ui.text("WS_DOES_NOT_FIT")
			_preview.update_stats(data.get("now"), data.get("after"))
		WorkshopTabsBar.Tab.CRAFTING:
			var data: Dictionary = WorkshopPresenter.preview_crafting(_selected_id)
			var recipe: RecipeDef = data.get("recipe")
			var prob: StringName = data.get("prob", &"")
			if recipe != null:
				_mats_bar.update_requirements(recipe.materials, recipe.riyal)
				_preview.update_recipe(recipe)
			_action_btn.disabled = (prob != &"")
			_action_btn.text = Ui.text(prob) if prob != &"" else Ui.text("WORKSHOP_BTN_CRAFT")


func _on_action_pressed() -> void:
	if _action_btn.disabled:
		return
	match _tabs.current_tab:
		WorkshopTabsBar.Tab.UPGRADE:
			if WorkshopService.upgrade(_selected_id):
				_after_mutation()
		WorkshopTabsBar.Tab.GEMSTONES:
			var hilt_id: StringName = GameState.equipment.get(&"rydan.hilt", &"grandfather_hilt")
			WorkshopService.set_stone(hilt_id, _selected_slot, _selected_id)
			_after_mutation()
		WorkshopTabsBar.Tab.CRAFTING:
			if WorkshopService.craft(_selected_id):
				_after_mutation()


func _remove_stone() -> void:
	var hilt_id: StringName = GameState.equipment.get(&"rydan.hilt", &"grandfather_hilt")
	WorkshopService.remove_stone(hilt_id, _selected_slot)
	_after_mutation()


func _after_mutation() -> void:
	_tabs.set_money(GameState.money)
	_items_list.populate(_tabs.current_tab)
	_refresh_sockets()
	_update_views()


func _refresh_sockets() -> void:
	var hilt_id: StringName = GameState.equipment.get(&"rydan.hilt", &"grandfather_hilt")
	var hilt := ContentDB.get_def("hilt", hilt_id) as HiltDef
	var open_count: int = Stones.open_slots(hilt, GameState.flags)
	var sock_list: Array = GameState.sockets.get(hilt_id, [])
	_sockets.set_sockets(sock_list, open_count, _selected_slot)
