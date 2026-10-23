class_name EquipmentHeroHeader
extends PanelContainer
## purpose: Hero info box (520x96 at 80,124) with name, class epithet, level and cyan XP progress bar.

var _name_lbl: Label
var _class_lbl: Label
var _lv_lbl: Label
var _xp_bar: ProgressBar


func _init() -> void:
	position = Vector2(80.0, 124.0)
	custom_minimum_size = Vector2(520.0, 96.0)
	size = Vector2(520.0, 96.0)
	theme_type_variation = &"InsetPanel"
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
	_class_lbl.text = Ui.text(c_def.name_key) if c_def != null else ""
	var hero_xp: int = GameState.xp.get(hero_id, 0)
	var levels_def := ContentDB.get_def("levels", &"default") as LevelsDef
	var lv: int = Progression.level(hero_xp, levels_def)
	_lv_lbl.text = "Lv %d" % lv
	if levels_def != null and lv < levels_def.xp_total.size():
		var cur_floor: int = levels_def.xp_total[lv - 1] if lv > 0 else 0
		var nxt: int = levels_def.xp_total[lv]
		_xp_bar.max_value = float(nxt - cur_floor)
		_xp_bar.value = float(hero_xp - cur_floor)
	else:
		_xp_bar.max_value = 1.0
		_xp_bar.value = 1.0


func _build_ui() -> void:
	for c: Node in get_children():
		c.queue_free()
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)

	var top_line := HBoxContainer.new()
	col.add_child(top_line)

	_name_lbl = Ui.label("", &"TitleLabel", Ui.style().colour(&"c_brass"))
	_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_line.add_child(_name_lbl)

	_class_lbl = Ui.label("", &"CaptionLabel", Ui.style().colour(&"c_epithet"))
	top_line.add_child(_class_lbl)

	_lv_lbl = Ui.label("Lv 1", &"NumberLabel")
	top_line.add_child(_lv_lbl)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(480.0, 10.0)
	_xp_bar.show_percentage = false
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Ui.style().colour(&"c_cyan")
	_xp_bar.add_theme_stylebox_override("fill", bar_style)
	col.add_child(_xp_bar)
