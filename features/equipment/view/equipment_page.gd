class_name EquipmentPage
extends PanelContainer
## The equipment layout: title and hero tabs on top, the slot lists on the left, the item detail and stat
## comparison on the right, Confirm with the back hint at the bottom. Only builds; EquipmentScreen owns the state.

var detail: EquipmentDetail
var confirm_button: Button
var _tabs: HBoxContainer
var _list: VBoxContainer
var _tab_group := ButtonGroup.new()


func build() -> void:
	var style: UiStyleDef = Ui.style()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", style.size(&"s_gap"))
	add_child(page)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", style.size(&"s_margin"))
	page.add_child(head)
	var title: Label = Ui.label(Ui.text("WORKSHOP_TITLE"), &"TitleLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_tabs = HBoxContainer.new()
	head.add_child(_tabs)
	page.add_child(Ui.divider())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", style.size(&"s_margin"))
	page.add_child(body)
	body.add_child(_build_list(style))
	body.add_child(_build_detail())
	page.add_child(_footer(style))


## A hero tab (toggle, exclusive with the others).
func add_tab(content: String) -> Button:
	var tab := Button.new()
	tab.text = content
	tab.theme_type_variation = &"TabButton"
	tab.toggle_mode = true
	tab.button_group = _tab_group
	_tabs.add_child(tab)
	return tab


func clear_list() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


func add_to_list(node: Control) -> void:
	_list.add_child(node)


func _build_list(style: UiStyleDef) -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.0
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", style.size(&"s_gap") / 2)
	scroll.add_child(_list)
	return scroll


func _build_detail() -> Control:
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"InsetPanel"
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 1.1
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	detail = EquipmentDetail.new()
	detail.build()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(detail)
	return frame


func _footer(style: UiStyleDef) -> HBoxContainer:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", style.size(&"s_margin"))
	confirm_button = Button.new()
	confirm_button.text = Ui.text("WORKSHOP_CONFIRM")
	confirm_button.custom_minimum_size = Vector2(style.size(&"s_button_h") * 6.0, style.size(&"s_button_h") * 1.3)
	footer.add_child(confirm_button)
	var hint: Label = Ui.label(Ui.text("WORKSHOP_BACK_HINT"), &"MutedLabel")
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(hint)
	return footer
