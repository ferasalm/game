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
var _preview: VBoxContainer
var _preview_text: Label
var _preview_bar: ProgressBar
var _preview_hp: int = 0
var _preview_sp: int = 0
var _preview_usable: bool = true
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
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_face = CharacterIcons.face(hero, tint if tint.a > 0.0 else style.colour(&"c_party"))
	frame.add_child(_face)
	line.add_child(frame)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
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
	_build_preview(column)
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


## Shows what an item would give this hero: a green segment and line; an unusable hero greys out.
func set_item_preview(hp_gain: int, sp_gain: int, text: String, usable: bool) -> void:
	_preview_hp = hp_gain
	_preview_sp = sp_gain
	_preview_usable = usable
	_preview.visible = true
	var style: UiStyleDef = Ui.style()
	_preview_text.text = text if usable else Ui.text("ITEMS_FULL")
	_preview_text.add_theme_color_override("font_color", style.colour(&"c_good" if usable else &"c_disabled"))
	var gain: int = hp_gain if hp_gain > 0 else sp_gain
	_preview_bar.visible = usable and gain > 0
	var top: float = _hp_bar.max_value if hp_gain > 0 else _sp_bar.max_value
	_preview_bar.max_value = maxf(top, 1.0)
	_preview_bar.value = float(gain)
	modulate = Color.WHITE if usable else style.colour(&"c_disabled")


## Removes the item preview from this card.
func clear_item_preview() -> void:
	_preview_hp = 0
	_preview_sp = 0
	_preview_usable = true
	if _preview != null:
		_preview.visible = false
	modulate = Color.WHITE


func preview_hp_gain() -> int:
	return _preview_hp


func preview_sp_gain() -> int:
	return _preview_sp


func preview_text() -> String:
	return _preview_text.text if _preview_text != null else ""


func preview_usable() -> bool:
	return _preview_usable


func hp_text() -> String:
	return _hp_text.text


func sp_text() -> String:
	return _sp_text.text


func is_ko() -> bool:
	return _ko.visible


func hp_value() -> float:
	return _hp_bar.value


func _build_preview(parent: Control) -> void:
	var style: UiStyleDef = Ui.style()
	_preview = VBoxContainer.new()
	_preview.add_theme_constant_override("separation", 2)
	_preview.visible = false
	_preview_text = Ui.label("", &"SmallLabel", style.colour(&"c_good"))
	_preview.add_child(_preview_text)
	_preview_bar = ProgressBar.new()
	_preview_bar.show_percentage = false
	_preview_bar.custom_minimum_size.y = 6.0
	_preview_bar.add_theme_stylebox_override("background", UiBoxes.bar_back(style))
	var fill := StyleBoxFlat.new()
	fill.bg_color = style.colour(&"c_good")
	fill.set_corner_radius_all(2)
	_preview_bar.add_theme_stylebox_override("fill", fill)
	_preview.add_child(_preview_bar)
	parent.add_child(_preview)


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
