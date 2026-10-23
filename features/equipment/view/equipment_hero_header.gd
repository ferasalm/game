class_name EquipmentHeroHeader
extends PanelContainer
## purpose: Hero info box (520x110 at 80,124) with portrait face, name, class, Lv N, and HP/SP/XP bars.

var _name_lbl: Label
var _class_lbl: Label
var _lv_lbl: Label
var _hp_bar: ProgressBar
var _hp_text: Label
var _sp_bar: ProgressBar
var _sp_text: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _face_box: PanelContainer
var _face: Control


func _init() -> void:
	var style: UiStyleDef = Ui.style()
	position = Vector2(80.0, 124.0)
	custom_minimum_size = Vector2(520.0, 104.0)
	size = Vector2(520.0, 104.0)
	var panel_box: StyleBoxTexture = UiBoxes.panel(style, &"panel")
	panel_box.content_margin_top = 4.0
	panel_box.content_margin_bottom = 4.0
	panel_box.content_margin_left = 6.0
	panel_box.content_margin_right = 6.0
	add_theme_stylebox_override("panel", panel_box)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build_ui()


func set_hero(hero_id: StringName) -> void:
	var def := ContentDB.get_def("combatant", hero_id) as CombatantDef
	_name_lbl.text = Ui.text(def.name_key) if def != null else String(hero_id)
	var c_def: ClassDef = null
	for c_id: StringName in ContentDB.ids("class"):
		var c := ContentDB.get_def("class", c_id) as ClassDef
		if c != null and c.hero == hero_id:
			c_def = c
			break
	_class_lbl.text = "(%s)" % Ui.text(c_def.name_key) if c_def != null else ""
	_update_vitals(hero_id, def)
	_update_xp(hero_id)
	_update_face(hero_id)


func lv_text() -> String:
	return _lv_lbl.text if _lv_lbl != null else ""


func lv_label() -> Label:
	return _lv_lbl


func portrait_face() -> Control:
	return _face


func _build_ui() -> void:
	for c: Node in get_children():
		c.queue_free()
	var style: UiStyleDef = Ui.style()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	_face_box = PanelContainer.new()
	_face_box.custom_minimum_size = Vector2(96.0, 96.0)
	_face_box.clip_contents = true
	var med_box: StyleBoxFlat = UiBoxes.medallion(style, style.colour(&"c_brass"))
	med_box.set_content_margin_all(2.0)
	_face_box.add_theme_stylebox_override("panel", med_box)
	hbox.add_child(_face_box)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 3)
	hbox.add_child(col)

	_build_top_line(col, style)
	_build_stat_bars(col, style)


func _build_top_line(parent: Control, style: UiStyleDef) -> void:
	var top_line := HBoxContainer.new()
	top_line.add_theme_constant_override("separation", 6)
	parent.add_child(top_line)

	_name_lbl = Ui.label("", &"NameLabel", style.colour(&"c_brass"))
	_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_line.add_child(_name_lbl)

	_class_lbl = Ui.label("", &"CaptionLabel", style.colour(&"c_epithet"))
	top_line.add_child(_class_lbl)

	_lv_lbl = Ui.label("Lv 1", &"CaptionLabel", style.colour(&"c_text"))
	top_line.add_child(_lv_lbl)


func _build_stat_bars(parent: Control, style: UiStyleDef) -> void:
	var hp_dict: Dictionary = _make_bar_row(parent, Ui.text("UI_HP"), &"HpBar", 8.0, style)
	_hp_bar = hp_dict["bar"]
	_hp_text = hp_dict["text"]

	var sp_dict: Dictionary = _make_bar_row(parent, Ui.text("UI_SP"), &"SpBar", 8.0, style)
	_sp_bar = sp_dict["bar"]
	_sp_text = sp_dict["text"]

	var xp_dict: Dictionary = _make_bar_row(parent, "XP", &"", 6.0, style)
	_xp_bar = xp_dict["bar"]
	_xp_text = xp_dict["text"]
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = style.colour(&"c_cyan")
	xp_fill.set_corner_radius_all(2)
	_xp_bar.add_theme_stylebox_override("fill", xp_fill)


func _make_bar_row(parent: Control, tag_text: String, kind: StringName, bar_h: float, style: UiStyleDef) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var tag: Label = Ui.label(tag_text, &"CaptionLabel", style.colour(&"c_cyan"))
	tag.custom_minimum_size.x = 24.0
	tag.add_theme_font_size_override("font_size", style.size(&"s_font_small"))
	row.add_child(tag)
	var bar := ProgressBar.new()
	if kind != &"":
		bar.theme_type_variation = kind
	bar.show_percentage = false
	bar.custom_minimum_size.y = bar_h
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UiBoxes.bar_back(style))
	row.add_child(bar)
	var text_lbl: Label = Ui.label("", &"SmallLabel")
	text_lbl.custom_minimum_size.x = 64.0
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	text_lbl.add_theme_font_size_override("font_size", style.size(&"s_font_small"))
	row.add_child(text_lbl)
	return {"bar": bar, "text": text_lbl}


func _update_vitals(hero_id: StringName, def: CombatantDef) -> void:
	var max_hp: int = def.max_hp if def != null else 1
	var max_sp: int = def.max_sp if def != null else 1
	var vitals: Vector2i = PauseLogic.vitals_of(GameState.get(&"vitals"), hero_id, max_hp, max_sp)
	_hp_bar.max_value = float(max_hp)
	_hp_bar.value = float(vitals.x)
	_hp_text.text = "%d/%d" % [vitals.x, max_hp]
	_sp_bar.max_value = float(max_sp)
	_sp_bar.value = float(vitals.y)
	_sp_text.text = "%d/%d" % [vitals.y, max_sp]


func _update_xp(hero_id: StringName) -> void:
	var hero_xp: int = GameState.xp.get(hero_id, 0)
	var levels_def := ContentDB.get_def("levels", &"default") as LevelsDef
	var lv: int = Progression.level(hero_xp, levels_def)
	_lv_lbl.text = "Lv %d" % lv
	if levels_def != null and lv < levels_def.xp_total.size():
		var cur_floor: int = levels_def.xp_total[lv - 1] if lv > 0 else 0
		var nxt: int = levels_def.xp_total[lv]
		_xp_bar.max_value = float(nxt - cur_floor)
		_xp_bar.value = float(hero_xp - cur_floor)
		_xp_text.text = "%d/%d" % [hero_xp - cur_floor, nxt - cur_floor]
	else:
		_xp_bar.max_value = 1.0
		_xp_bar.value = 1.0
		_xp_text.text = "MAX"


func _update_face(hero_id: StringName) -> void:
	if _face_box == null:
		return
	for c: Node in _face_box.get_children():
		c.queue_free()
	_face = PortraitFaces.face(hero_id)
	_face.custom_minimum_size = Vector2(96.0, 96.0)
	_face_box.add_child(_face)
