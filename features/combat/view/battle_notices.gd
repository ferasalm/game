class_name BattleNotices
extends Control
## The words the HUD says to the player: a compact banner in the upper middle ("Interrupted!") that fades, the one-time
## tip under the top bar, and the key hint strip at the bottom (shown only while a menu is open).

var _view: BattleViewDef
var _banner: Label
var _banner_tween: Tween = null
var _tip: PanelContainer
var _tip_label: Label
var _tip_timer: SceneTreeTimer = null
var _strip: PromptStrip
var _help: Label


func setup(view: BattleViewDef, bar_height: float) -> void:
	_view = view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner = BattleStyle.label("", &"BannerLabel")
	_banner.add_theme_font_size_override("font_size", view.banner_font_size)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = view.banner_anchor_y
	_banner.anchor_bottom = view.banner_anchor_y
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.visible = false
	add_child(_banner)
	_build_tip(view, bar_height)
	_build_help(view)
	_strip = Ui.prompt_strip([{"key": "accept", "text": "PROMPT_SELECT"},
			{"key": "back", "text": "PROMPT_BACK"}, {"key": "info", "text": "PROMPT_INFO"}])
	_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_strip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_strip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_strip.offset_bottom = -Ui.style().size(&"s_strip_bottom")
	_strip.visible = false
	add_child(_strip)


func _build_tip(view: BattleViewDef, bar_height: float) -> void:
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", UiBoxes.panel(Ui.style(), &"plate"))
	_tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_tip.offset_left = view.margin
	_tip.offset_top = bar_height + view.margin / 2.0
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_label = BattleStyle.label("", &"SmallLabel")
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.custom_minimum_size.x = view.tip_w
	_tip.add_child(_tip_label)
	_tip.visible = false
	add_child(_tip)


func _build_help(view: BattleViewDef) -> void:
	_help = BattleStyle.label("", &"SmallLabel")
	_help.add_theme_font_size_override("font_size", view.menu_font + 2)
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_help.offset_bottom = -(Ui.style().size(&"s_strip_bottom") + Ui.style().size(&"s_prompt_h") + view.margin / 2.0)
	add_child(_help)


## Big text that fades over banner_seconds ("Interrupted!", "Reverse stab!").
func show_banner(content: String) -> void:
	_banner.text = content
	_banner.modulate.a = 1.0
	_banner.visible = true
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, _view.banner_seconds)
	_banner_tween.tween_callback(_banner.hide)


func banner_text() -> String:
	return _banner.text if _banner.visible else ""


## A one-time hint: shown only if GameState.flags has no `flag` yet, which is then set.
func show_tip(flag: StringName, key: String) -> void:
	if GameState.flags.get(flag, false):
		return
	GameState.flags[flag] = true
	_tip_label.text = BattleStyle.text(key)
	_tip.visible = true
	if _tip_timer != null and _tip_timer.timeout.is_connected(_tip.hide):
		_tip_timer.timeout.disconnect(_tip.hide)
	_tip_timer = get_tree().create_timer(_view.tip_seconds) if is_inside_tree() else null
	if _tip_timer != null:
		_tip_timer.timeout.connect(_tip.hide)


## The one line of help over the key hints: a move's description, or in the warning colour why a choice failed.
func show_help(content: String, warning: bool) -> void:
	_help.text = content
	var style: UiStyleDef = Ui.style()
	_help.add_theme_color_override("font_color", style.colour(&"c_bad" if warning else &"c_gypsum_dim"))


func help_text() -> String:
	return _help.text


func tip_text() -> String:
	return _tip_label.text if _tip.visible else ""


## The key hints show while a menu is open and hide when nothing waits for a command.
func show_hints(on: bool) -> void:
	_strip.visible = on
	_help.visible = on


func hints_visible() -> bool:
	return _strip.visible


## The screen rects of the notices that show now (banner, tip, key hints).
func visible_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for control: Control in [_banner, _tip, _strip, _help]:
		if control.is_visible_in_tree() and control.get_global_rect().get_area() > 0.0:
			out.append(control.get_global_rect())
	return out
