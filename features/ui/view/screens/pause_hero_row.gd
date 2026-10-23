class_name PauseHeroRow
extends PanelContainer
## One hero row in the pause party panel: face 160x160, name, class, HP/SP bars, KO state.

var hero_id: StringName = &""
var _face: TextureRect
var _face_box: PanelContainer
var _name_label: Label
var _class_label: Label
var _lv_node: Control
var _xp_bar: ProgressBar
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

	_face_box = PanelContainer.new()
	_face_box.custom_minimum_size = Vector2(160, 160)
	_face_box.add_theme_stylebox_override("panel", UiBoxes.medallion(style, style.colour(&"c_brass")))
	_face = TextureRect.new()
	_face.texture = CharacterIcons.texture(hero)
	_face.custom_minimum_size = Vector2(160, 160)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face_box.add_child(_face)
	row.add_child(_face_box)

	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(middle)

	var name_str: String = Ui.text(def.name_key) if def != null else String(hero)
	_name_label = Ui.label(name_str, &"TitleLabel", style.colour(&"c_brass"))
	middle.add_child(_name_label)

	var prog_space := VBoxContainer.new()
	prog_space.custom_minimum_size = Vector2(360, 40)
	_class_label = Ui.label("", &"SmallLabel", style.colour(&"c_epithet"))
	_class_label.name = "ClassLabel"
	_class_label.visible = false  # TODO(rpg-progression)
	prog_space.add_child(_class_label)
	_lv_node = Ui.label("", &"NumberLabel")
	_lv_node.name = "LvNode"
	_lv_node.visible = false  # TODO(rpg-progression)
	prog_space.add_child(_lv_node)
	_xp_bar = ProgressBar.new()
	_xp_bar.name = "XpBar"
	_xp_bar.custom_minimum_size = Vector2(360, 10)
	_xp_bar.visible = false  # TODO(rpg-progression)
	prog_space.add_child(_xp_bar)
	middle.add_child(prog_space)

	var stats := VBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.custom_minimum_size.x = 450
	row.add_child(stats)

	var max_hp: int = def.max_hp if def != null else 1
	var max_sp: int = def.max_sp if def != null else 1
	_hp_bar = _stat_bar(stats, "UI_HP", &"HpBar", max_hp, true)
	_sp_bar = _stat_bar(stats, "UI_SP", &"SpBar", max_sp, false)

	_ko_label = Ui.label(Ui.text("PAUSE_KO"), &"NumberLabel", style.colour(&"c_bad"))
	_ko_label.name = "KoLabel"
	_ko_label.visible = false
	stats.add_child(_ko_label)

	var now: Vector2i = PauseLogic.vitals_of(GameState.get(&"vitals"), hero, max_hp, max_sp)
	update(now.x, now.y)
	return self


func update(hp: int, sp: int) -> void:
	_hp_text.text = "%d/%d" % [hp, int(_hp_bar.max_value)]
	_sp_text.text = "%d/%d" % [sp, int(_sp_bar.max_value)]
	_hp_bar.value = hp
	_sp_bar.value = sp
	var dead: bool = hp <= 0
	_ko_label.visible = dead
	modulate = Ui.style().colour(&"c_disabled") if dead else Color.WHITE


func is_ko() -> bool:
	return _ko_label.visible


func ko_label() -> Label:
	return _ko_label


func lv_node() -> Control:
	return _lv_node


func xp_bar() -> ProgressBar:
	return _xp_bar


func hp_bar() -> ProgressBar:
	return _hp_bar


func sp_bar() -> ProgressBar:
	return _sp_bar


func face_rect() -> TextureRect:
	return _face


func _stat_bar(parent: Control, tag_key: String, kind: StringName, maximum: int, is_hp: bool) -> ProgressBar:
	var line := HBoxContainer.new()
	var tag: Label = Ui.label(Ui.text(tag_key), &"CaptionLabel")
	tag.custom_minimum_size.x = 32
	line.add_child(tag)
	var bar := ProgressBar.new()
	bar.theme_type_variation = kind
	bar.show_percentage = false
	bar.max_value = maximum
	bar.custom_minimum_size = Vector2(420, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(bar)
	var numbers: Label = Ui.label("", &"NumberLabel")
	numbers.custom_minimum_size.x = 90
	line.add_child(numbers)
	if is_hp:
		_hp_text = numbers
	else:
		_sp_text = numbers
	parent.add_child(line)
	return bar
