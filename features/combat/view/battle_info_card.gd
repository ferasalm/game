class_name BattleInfoCard
extends PanelContainer
## The small card beside a fighter that is pointed at (mouse over it, or the focus on it while targeting). A hero:
## name, HP and SP with numbers. A foe: name, an HP bar and what it is casting. It stays while pointed at and fades
## after the view's delay. It sits next to the fighter and never over another fighter.

var vitals: BattleVitals
var _sim: BattleSim
var _view: BattleViewDef
var _shown_hp: Dictionary[StringName, int]
var _fighters: BattleFighters
var _intent: Label
var _unit: UnitState = null
var _idle: float = INF


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int], fighters: BattleFighters) -> void:
	_sim = sim
	_view = view
	_shown_hp = shown_hp
	_fighters = fighters
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = view.info_w
	BattleStyle.tight_panel(self, &"PanelContainer", view)
	var box := VBoxContainer.new()
	add_child(box)
	vitals = BattleVitals.new()
	vitals.setup(view)
	box.add_child(vitals)
	_intent = BattleStyle.label("", &"SmallLabel", view.enemy_color)
	box.add_child(_intent)
	visible = false


## This fighter is pointed at right now: the card shows it (and restarts its fade delay).
func point(unit_id: StringName) -> void:
	_idle = 0.0
	if _unit != null and _unit.unit_id == unit_id:
		return
	_unit = _sim.timeline.find(unit_id)
	if _unit == null:
		return
	var hero: bool = _unit.side == 0
	vitals.show_unit(BattleStyle.unit_name(_sim, _unit), _unit.def.max_hp, _unit.def.max_sp if hero else 0, hero)


func shown_unit() -> StringName:
	return _unit.unit_id if _unit != null and visible else &""


func update(delta: float, rects: Dictionary[StringName, Rect2], extra: Array[Rect2], screen: Rect2) -> void:
	_idle += delta
	var alpha: float = HudLayout.fade_alpha(_idle, _view.info_delay, _view.info_fade)
	visible = _unit != null and alpha > 0.0
	modulate.a = alpha
	if not visible:
		return
	vitals.update(_shown_hp.get(_unit.unit_id, 0), _unit.sp)
	var line: String = _fighters.intent_text(_unit.unit_id) if _unit.side == 1 else ""
	_intent.text = BattleStyle.text("BATTLE_INTENT_LINE") % line if not line.is_empty() else ""
	_intent.visible = not line.is_empty()
	size = get_combined_minimum_size()
	var blockers: Array[Rect2] = extra.duplicate()
	for unit_id: StringName in rects:
		if unit_id != _unit.unit_id:
			blockers.append(rects[unit_id])
	var around: Array[Rect2] = HudLayout.beside(rects.get(_unit.unit_id, Rect2()), size, _view.info_gap)
	var order: Array[Rect2] = [around[2], around[0], around[1], around[3]]
	position = HudLayout.pick(order, blockers, screen).position
