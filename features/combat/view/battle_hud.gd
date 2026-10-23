class_name BattleHud
extends CanvasLayer
## The battle HUD (v3), built in code and minimal at rest: a thin timeline on top (with the chosen target's name),
## a slim vitals strip under each hero's feet, and nothing else. A hero's turn adds that hero's card and a compact
## command menu beside them (BattleTurnPanel); pointing at a fighter (mouse, or the focus while targeting) adds a
## small info card. Works with keyboard, mouse and gamepad through Button focus. Nothing may cover a fighter.

## The player committed a move on a target in the command menu.
signal move_chosen(action: ActionDef, target_id: StringName)
## The player committed a herb (and a target; &"" for the party herb) in the Items list.
signal item_chosen(item_id: StringName, target_id: StringName)
## The target picker's focus moved (&"" when it closed).
signal target_focused(unit_id: StringName)
## The end panel's pick: &"victory", &"retry" or &"defeat".
signal end_chosen(result: StringName)

var menu: BattleCommandMenu
var item_menu: BattleItemMenu
var timeline_bar: BattleTimelineBar
var strips: BattleStrips
var turn_panel: BattleTurnPanel
var info_card: BattleInfoCard
var notices: BattleNotices
var end_panel: BattleEndPanel
var rects: BattleRects
## Every fighter's screen rect as of the last refresh().
var fighter_rects: Dictionary[StringName, Rect2] = {}
var _sim: BattleSim
var _view: BattleViewDef
var _unit_ids: Array[StringName] = []
var _target: StringName = &""


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int], camera: Camera3D,
		fighters: BattleFighters) -> void:
	_sim = sim
	_view = view
	for unit: UnitState in sim.timeline.units:
		_unit_ids.append(unit.unit_id)
	rects = BattleRects.new()
	rects.setup(camera, fighters, view.rect_pad)
	var root: Control = Ui.screen_root()
	add_child(root)
	timeline_bar = BattleTimelineBar.new()
	root.add_child(timeline_bar)
	timeline_bar.setup(sim, view, shown_hp)
	strips = BattleStrips.new()
	root.add_child(strips)
	strips.setup(sim, view, shown_hp)
	menu = BattleCommandMenu.new()
	menu.setup(sim, view)
	menu.chosen.connect(move_chosen.emit)
	menu.target_focused.connect(_on_target_focused)
	menu.items_requested.connect(_open_items)
	menu.help_changed.connect(_on_help)
	item_menu = BattleItemMenu.new()
	item_menu.setup(sim, view)
	item_menu.chosen.connect(item_chosen.emit)
	item_menu.target_focused.connect(_on_target_focused)
	item_menu.closed.connect(_close_items)
	item_menu.help_changed.connect(_on_help)
	turn_panel = BattleTurnPanel.new()
	root.add_child(turn_panel)
	turn_panel.setup(view, shown_hp, menu, item_menu)
	info_card = BattleInfoCard.new()
	root.add_child(info_card)
	info_card.setup(sim, view, shown_hp, fighters)
	notices = BattleNotices.new()
	root.add_child(notices)
	notices.setup(view, timeline_bar.height())
	end_panel = BattleEndPanel.new()
	root.add_child(end_panel)
	end_panel.setup(view)
	end_panel.picked.connect(end_chosen.emit)


func _process(delta: float) -> void:
	refresh(delta)


## One frame of the HUD: project the fighters, then place the strips, the turn panel and the info card. `mouse` is
## where the pointer is (Vector2.INF: ask the viewport; tests pass a point).
func refresh(delta: float, mouse: Vector2 = Vector2.INF) -> void:
	if _sim == null:
		return
	var screen: Rect2 = get_viewport().get_visible_rect()
	var area: Rect2 = screen.grow_individual(0.0, -(timeline_bar.height() + _view.strip_gap), 0.0, 0.0)
	fighter_rects = rects.all(_unit_ids)
	strips.update(delta, fighter_rects, area)
	turn_panel.update(_sim, fighter_rects, area)
	var pointed: StringName = _target
	if mouse == Vector2.INF:
		mouse = get_viewport().get_mouse_position()
	if pointed == &"" and screen.has_point(mouse):
		pointed = HudLayout.hit(fighter_rects, mouse)
	if pointed != &"" and not end_panel.visible:
		info_card.point(pointed)
	var extra: Array[Rect2] = [turn_panel.rect()]
	info_card.update(delta, fighter_rects, extra, area)
	notices.show_hints(turn_panel.visible)


func open_menu(hero: UnitState) -> void:
	menu.open(hero)
	show_tip(&"tip_command_seen", "UI_TIP_COMMAND")


func close_menu() -> void:
	item_menu.close()
	menu.visible = false
	menu.close()
	_on_target_focused(&"")


func show_end(result: StringName) -> void:
	close_menu()
	end_panel.show_result(result)


## Big text that fades over banner_seconds ("Interrupted!", "Reverse stab!").
func show_banner(content: String) -> void:
	notices.show_banner(content)


func banner_text() -> String:
	return notices.banner_text()


## A one-time hint: shown only if GameState.flags has no `flag` yet, which is then set.
func show_tip(flag: StringName, key: String) -> void:
	notices.show_tip(flag, key)


func tip_text() -> String:
	return notices.tip_text()


## The screen rect of everything the HUD shows at this moment, for the "nothing covers a fighter" rule. The top bar
## counts by its track and icons (its full-width box is mostly empty).
func visible_rects() -> Array[Rect2]:
	var out: Array[Rect2] = timeline_bar.visible_rects()
	out.append_array(strips.visible_rects())
	out.append_array(notices.visible_rects())
	for panel: Control in [turn_panel, info_card, end_panel]:
		if panel.is_visible_in_tree():
			out.append(panel.get_global_rect())
	return out


func _on_help(content: String, warning: bool) -> void:
	notices.show_help(content, warning)


func _open_items() -> void:
	menu.visible = false
	item_menu.open(menu.hero())


func _close_items() -> void:
	menu.visible = true
	menu.return_from_items()


## The target picker's focus moved: the top bar names it, its timeline icon rises, the info card follows it.
func _on_target_focused(unit_id: StringName) -> void:
	_target = unit_id
	var unit: UnitState = _sim.timeline.find(unit_id) if unit_id != &"" else null
	var caption: String = BattleStyle.text("BATTLE_TARGET") % BattleStyle.unit_name(_sim, unit) if unit != null else ""
	timeline_bar.set_target(unit_id, caption)
	var move: ActionDef = menu._move if menu != null else null
	var hero: UnitState = menu.hero() if menu != null else null
	if unit_id != &"" and move != null and move.id == &"piston_jab" and hero != null and unit != null:
		timeline_bar.show_ghost(unit_id, _sim.knockback_preview(hero, move, unit))
	else:
		timeline_bar.hide_ghost()
	target_focused.emit(unit_id)
