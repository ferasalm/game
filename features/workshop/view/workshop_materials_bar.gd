class_name WorkshopMaterialsBar
extends PanelContainer
## purpose: Panel (760x120 at 580,780) showing required materials, have/need counts, and riyal cost.

var _title: Label
var _items_box: HBoxContainer
var _riyal_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(760.0, 120.0)
	size = Vector2(760.0, 120.0)
	position = Vector2(580.0, 780.0)
	theme_type_variation = &"PlatePanel"
	_build_ui()


## Updates the display with required materials dictionary and riyal cost.
func update_requirements(materials: Dictionary, riyal_cost: int, is_max: bool = false) -> void:
	for child: Node in _items_box.get_children():
		child.queue_free()

	if is_max:
		var max_lbl := Ui.label(Ui.text("WS_MAX"), &"NameLabel", Ui.style().colour(&"c_muted"))
		_items_box.add_child(max_lbl)
		_riyal_label.text = ""
		return

	if materials.is_empty() and riyal_cost <= 0:
		var free_lbl := Ui.label(Ui.text("WORKSHOP_FREE"), &"NameLabel", Ui.style().colour(&"c_brass"))
		_items_box.add_child(free_lbl)
		_riyal_label.text = ""
		return

	var style: UiStyleDef = Ui.style()
	for mat_id: Variant in materials:
		var m_id := mat_id as StringName
		var need: int = int(materials[mat_id])
		var have: int = int(GameState.materials.get(m_id, 0))
		var mat_def := ContentDB.get_def("material", m_id) as MaterialDef
		var name_str: String = Ui.text(mat_def.name_key) if mat_def != null and mat_def.name_key != "" else String(m_id)

		var item_box := HBoxContainer.new()
		item_box.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48.0, 48.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_box.add_child(icon)

		var info_box := VBoxContainer.new()
		info_box.add_child(Ui.label(name_str, &"SmallLabel", style.colour(&"c_text")))
		var ratio_col: Color = style.colour(&"c_good" if have >= need else &"c_bad")
		info_box.add_child(Ui.label("(%d/%d)" % [have, need], &"NumberLabel", ratio_col))
		item_box.add_child(info_box)

		_items_box.add_child(item_box)

	if riyal_cost > 0:
		var money_has: int = GameState.money
		var money_col: Color = style.colour(&"c_brass" if money_has >= riyal_cost else &"c_bad")
		_riyal_label.text = "%s %s" % [PauseLogic.grouped(riyal_cost), Ui.text("MONEY_GLYPH")]
		_riyal_label.add_theme_color_override("font_color", money_col)
	else:
		_riyal_label.text = ""


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var header := HBoxContainer.new()
	_title = Ui.label(Ui.text("WORKSHOP_MATERIALS_REQUIRED"), &"CaptionLabel", Ui.style().colour(&"c_brass"))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_riyal_label = Ui.label("", &"NumberLabel", Ui.style().colour(&"c_brass"))
	header.add_child(_riyal_label)
	vbox.add_child(header)

	_items_box = HBoxContainer.new()
	_items_box.add_theme_constant_override("separation", 24)
	vbox.add_child(_items_box)
