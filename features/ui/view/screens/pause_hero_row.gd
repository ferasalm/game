class_name PauseHeroRow
extends PanelContainer
## purpose: One hero row in the pause party panel: face 160x160, name, class, HP/SP bars, KO state.

var hero_id: StringName = &""
var _face: TextureRect
var _face_box: PanelContainer
var _name_label: Label
var _class_label: Label
var _lv_node: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _hp_bar: ProgressBar
var _sp_bar: ProgressBar
var _hp_text: Label
var _sp_text: Label
var _ko_label: Label


func setup(hero: StringName) -> PauseHeroRow:
	hero_id = hero
	var style: UiStyleDef = Ui.style()
	var def := ContentDB.get_def("combatant", hero) as CombatantDef
	theme_type_variation = &"InsetPanel"
	custom_minimum_size = Vector2(1260, 200)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", style.size(&"s_margin"))
	add_child(row)

	_build_face(row, style, hero)
	_build_middle(row, style, def, hero)
	_build_stats(row, style, def, hero)
	return self


func _build_face(parent: Control, style: UiStyleDef, hero: StringName) -> void:
	_face_box = PanelContainer.new()
	_face_box.custom_minimum_size = Vector2(160, 160)
	_face_box.add_theme_stylebox_override("panel", UiBoxes.medallion(style, style.colour(&"c_brass")))
	_face = TextureRect.new()
	var tex: Texture2D = PortraitFaces.bust_texture(hero)
	_face.texture = tex if tex != null else CharacterIcons.disc(style.colour(&"c_party").darkened(0.45))
	_face.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_face.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_face_box.add_child(_face)
	parent.add_child(_face_box)


func _build_middle(parent: Control, style: UiStyleDef, def: CombatantDef, hero: StringName) -> void:
	var middle := VBoxContainer.new()
	middle.custom_minimum_size.x = 480.0
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 2)
	parent.add_child(middle)

	var name_str: String = Ui.text(def.name_key) if def != null else String(hero)
	_name_label = Ui.label(name_str, &"TitleLabel", style.colour(&"c_brass"))
	middle.add_child(_name_label)

	_class_label = Ui.label("", &"SmallLabel", style.colour(&"c_epithet"))
	_class_label.name = "ClassLabel"
	middle.add_child(_class_label)

	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", style.size(&"s_pad"))
	_lv_node = Ui.label("", &"NumberLabel")
	_lv_node.name = "LvNode"
	xp_row.add_child(_lv_node)

	xp_row.add_child(Ui.label("XP", &"CaptionLabel", style.colour(&"c_cyan")))

	_xp_bar = ProgressBar.new()
	_xp_bar.name = "XpBar"
	_xp_bar.custom_minimum_size = Vector2(360, 10)
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.show_percentage = false
	_xp_bar.add_theme_stylebox_override("background", UiBoxes.bar_back(style))
	_xp_bar.add_theme_stylebox_override("fill", UiBoxes.bar_fill(style, &"c_cyan", &"c_cyan"))
	xp_row.add_child(_xp_bar)

	_xp_text = Ui.label("", &"NumberLabel", style.colour(&"c_muted"))
	xp_row.add_child(_xp_text)
	middle.add_child(xp_row)

	_refresh_progression(hero)


func _refresh_progression(hero: StringName) -> void:
	var cdef: ClassDef = null
	for class_id: StringName in ContentDB.ids("class"):
		var c := ContentDB.get_def("class", class_id) as ClassDef
		if c != null and c.hero == hero:
			cdef = c
			break
	_class_label.text = Ui.text(cdef.name_key) if cdef != null else ""
	var levels_def := ContentDB.get_def("levels", &"default") as LevelsDef
	var xp_amount: int = int(GameState.xp.get(hero, 0))
	var lv: int = Progression.level(xp_amount, levels_def)
	_lv_node.text = "Lv %d" % lv
	var next_xp: int = levels_def.xp_total[lv] if (levels_def != null and lv < levels_def.xp_total.size()) else xp_amount
	_xp_bar.max_value = next_xp
	_xp_bar.value = xp_amount
	_xp_text.text = "%d/%d" % [xp_amount, next_xp]


func _build_stats(parent: Control, style: UiStyleDef, def: CombatantDef, hero: StringName) -> void:
	var stats := VBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.custom_minimum_size.x = 550.0
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(stats)

	var max_hp: int = def.max_hp if def != null else 1
	var max_sp: int = def.max_sp if def != null else 1
	var hp_pair: Array[Node] = PauseStatBar.build(stats, "UI_HP", &"HpBar", max_hp)
	_hp_bar = hp_pair[0] as ProgressBar
	_hp_text = hp_pair[1] as Label
	var sp_pair: Array[Node] = PauseStatBar.build(stats, "UI_SP", &"SpBar", max_sp)
	_sp_bar = sp_pair[0] as ProgressBar
	_sp_text = sp_pair[1] as Label

	_ko_label = Ui.label(Ui.text("PAUSE_KO"), &"NumberLabel", style.colour(&"c_bad"))
	_ko_label.name = "KoLabel"
	_ko_label.visible = false
	stats.add_child(_ko_label)

	var now: Vector2i = PauseLogic.vitals_of(GameState.get(&"vitals"), hero, max_hp, max_sp)
	update(now.x, now.y)


func update(hp: int, sp: int) -> void:
	_hp_text.text = "%d/%d" % [hp, int(_hp_bar.max_value)]
	_sp_text.text = "%d/%d" % [sp, int(_sp_bar.max_value)]
	_hp_bar.value = hp
	_sp_bar.value = sp
	var dead: bool = hp <= 0
	_ko_label.visible = dead
	modulate = Ui.style().colour(&"c_disabled") if dead else Color.WHITE
	_refresh_progression(hero_id)


func is_ko() -> bool:
	return _ko_label.visible


func ko_label() -> Label:
	return _ko_label


func lv_node() -> Control:
	return _lv_node


func class_label() -> Label:
	return _class_label


func xp_bar() -> ProgressBar:
	return _xp_bar


func hp_bar() -> ProgressBar:
	return _hp_bar


func sp_bar() -> ProgressBar:
	return _sp_bar


func face_rect() -> TextureRect:
	return _face


func face_box() -> PanelContainer:
	return _face_box
