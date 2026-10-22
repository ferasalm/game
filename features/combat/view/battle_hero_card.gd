class_name BattleHeroCard
extends PanelContainer
## The acting hero's full card, on top of the turn panel: name, HP and SP with numbers. HP shown follows the played
## events (shown_hp), not the sim's finished tick.

var vitals: BattleVitals
var _unit: UnitState = null
var _shown_hp: Dictionary[StringName, int]


func setup(view: BattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_shown_hp = shown_hp
	BattleStyle.bare_panel(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals = BattleVitals.new()
	vitals.setup(view, false)
	add_child(vitals)


func show_hero(sim: BattleSim, unit: UnitState) -> void:
	_unit = unit
	vitals.show_unit(BattleStyle.unit_name(sim, unit), unit.def.max_hp, unit.def.max_sp, true)
	update()


func hero_id() -> StringName:
	return _unit.unit_id if _unit != null else &""


func update() -> void:
	if _unit != null:
		vitals.update(_shown_hp.get(_unit.unit_id, 0), _unit.sp)
