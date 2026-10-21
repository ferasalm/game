class_name PartyCard
extends PanelContainer
## A hero card: portrait icon, name, HP and SP bars with numbers. KO greys the portrait and shows "KO"; the active
## hero gets the brass plate frame. Bars glide to new values; the numbers change at once.
## Use: Ui.party_card(hero_id) (vitals from GameState), then update(hp, sp) when they change.

var hero_id: StringName = &""

var _hp_bar: ProgressBar
var _sp_bar: ProgressBar
var _hp_text: Label
var _sp_text: Label
var _ko: Label
var _face: Control
var _tween: Tween = null
var _target_hp: int = -1
var _target_sp: int = -1


## Builds the card for a combatant id. Returns self.
func setup(hero: StringName, tint: Color = Color.TRANSPARENT) -> PartyCard:
	hero_id = hero
	var style: UiStyleDef = Ui.style()
	var def := ContentDB.get_def("combatant", hero) as CombatantDef
	theme_type_variation = &"InsetPanel"
	custom_minimum_size = Vector2(style.size(&"s_card_w"), style.size(&"s_card_h"))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", style.size(&"s_pad"))
	add_child(line)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiBoxes.medallion(style, style.colour(&"c_brass")))
	frame.custom_minimum_size = Vector2.ONE * style.size(&"s_card_portrait")
	_face = CharacterIcons.face(hero, tint if tint.a > 0.0 else style.colour(&"c_party"))
	frame.add_child(_face)
	line.add_child(frame)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(column)
	var head := HBoxContainer.new()
	var name_label: Label = Ui.label(Ui.text(def.name_key) if def != null else String(hero), &"NameLabel")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	_ko = Ui.label(Ui.text("PAUSE_KO"), &"NumberLabel", style.colour(&"c_bad"))
	_ko.visible = false
	head.add_child(_ko)
	column.add_child(head)
	var max_hp: int = def.max_hp if def != null else 1
	var max_sp: int = def.max_sp if def != null else 1
	_hp_bar = _stat(column, "UI_HP", &"HpBar", max_hp)
	_sp_bar = _stat(column, "UI_SP", &"SpBar", max_sp)
	var now: Vector2i = PauseLogic.vitals_of(GameState.get(&"vitals"), hero, max_hp, max_sp)
	update(now.x, now.y, false)
	return self


## Shows new HP and SP; the bars glide when animate is true and the card is in the tree.
func update(hp: int, sp: int, animate: bool = true) -> void:
	_hp_text.text = "%d/%d" % [hp, int(_hp_bar.max_value)]
	_sp_text.text = "%d/%d" % [sp, int(_sp_bar.max_value)]
	_ko.visible = hp <= 0
	_face.modulate = Ui.style().colour(&"c_disabled") if hp <= 0 else Color.WHITE
	if hp == _target_hp and sp == _target_sp:
		return
	_target_hp = hp
	_target_sp = sp
	if _tween != null:
		_tween.kill()
	if not animate or not is_inside_tree():
		_hp_bar.value = hp
		_sp_bar.value = sp
		return
	_tween = UiMotion.tween(self).set_parallel(true)
	_tween.tween_property(_hp_bar, "value", float(hp), Ui.style().time(&"t_money_count"))
	_tween.tween_property(_sp_bar, "value", float(sp), Ui.style().time(&"t_money_count"))


## The acting hero gets the brass plate frame.
func set_active(on: bool) -> void:
	var style: UiStyleDef = Ui.style()
	add_theme_stylebox_override("panel", UiBoxes.panel(style, &"plate" if on else &"inset"))


func hp_text() -> String:
	return _hp_text.text


func sp_text() -> String:
	return _sp_text.text


func is_ko() -> bool:
	return _ko.visible


func hp_value() -> float:
	return _hp_bar.value


func _stat(parent: Control, tag_key: String, kind: StringName, maximum: int) -> ProgressBar:
	var line := HBoxContainer.new()
	var tag: Label = Ui.label(Ui.text(tag_key), &"CaptionLabel")
	tag.custom_minimum_size.x = Ui.style().size(&"s_icon") * 0.5
	line.add_child(tag)
	var bar := ProgressBar.new()
	bar.theme_type_variation = kind
	bar.show_percentage = false
	bar.max_value = maximum
	bar.custom_minimum_size.y = Ui.style().size(&"s_bar_h")
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(bar)
	var numbers: Label = Ui.label("", &"NumberLabel")
	line.add_child(numbers)
	if kind == &"HpBar":
		_hp_text = numbers
	else:
		_sp_text = numbers
	parent.add_child(line)
	return bar
