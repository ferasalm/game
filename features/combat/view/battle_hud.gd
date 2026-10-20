class_name BattleHud
extends CanvasLayer
## The battle HUD, built in code: timeline bar (top) with the one-time tip under it, party panel (bottom right),
## command menu (bottom left), the banner text and the end panel. Works with keyboard, mouse and gamepad through Button focus.

## The player committed a move on a target in the command menu.
signal move_chosen(action: ActionDef, target_id: StringName)
## The target picker's focus moved (&"" when it closed).
signal target_focused(unit_id: StringName)
## The end panel's pick: &"victory", &"retry" or &"defeat".
signal end_chosen(result: StringName)

var menu: BattleCommandMenu
var timeline_bar: BattleTimelineBar
var party_panel: BattlePartyPanel
var end_panel: BattleEndPanel
var _view: BattleViewDef
var _root: Control
var _banner: Label
var _banner_tween: Tween = null
var _tip: PanelContainer
var _tip_label: Label
var _tip_timer: SceneTreeTimer = null


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_view = view
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = Theme.new()
	_root.theme.default_font_size = view.font_size
	add_child(_root)
	timeline_bar = BattleTimelineBar.new()
	_root.add_child(timeline_bar)
	timeline_bar.setup(sim, view, shown_hp)
	party_panel = BattlePartyPanel.new()
	_root.add_child(party_panel)
	party_panel.setup(sim, view, shown_hp)
	menu = BattleCommandMenu.new()
	_root.add_child(menu)
	menu.setup(sim, view)
	menu.chosen.connect(move_chosen.emit)
	menu.target_focused.connect(target_focused.emit)
	_build_texts()
	end_panel = BattleEndPanel.new()
	_root.add_child(end_panel)
	end_panel.setup(view)
	end_panel.picked.connect(end_chosen.emit)


func open_menu(hero: UnitState) -> void:
	menu.open(hero)
	show_tip(&"tip_command_seen", "UI_TIP_COMMAND")


func close_menu() -> void:
	menu.close()
	target_focused.emit(&"")


func show_end(result: StringName) -> void:
	close_menu()
	end_panel.show_result(result)


## Big centred text that fades over banner_seconds ("Interrupted!", "Reverse stab!").
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


func tip_text() -> String:
	return _tip_label.text if _tip.visible else ""


func _build_texts() -> void:
	_banner = BattleStyle.label("", _view.highlight_color)
	_banner.add_theme_font_size_override("font_size", _view.banner_font_size)
	_banner.add_theme_constant_override("outline_size", roundi(_view.banner_font_size / 8.0))
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = _view.banner_anchor_y
	_banner.anchor_bottom = _view.banner_anchor_y
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.visible = false
	_root.add_child(_banner)
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", BattleStyle.panel(_view))
	_tip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_tip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tip.grow_vertical = Control.GROW_DIRECTION_END
	_tip.offset_top = timeline_bar.height() + _view.margin / 2.0
	_tip.offset_bottom = _tip.offset_top
	_tip_label = BattleStyle.label("")
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.custom_minimum_size.x = _view.menu_width + _view.party_panel_width - _view.margin * 4.0
	_tip.add_child(_tip_label)
	_tip.visible = false
	_root.add_child(_tip)
