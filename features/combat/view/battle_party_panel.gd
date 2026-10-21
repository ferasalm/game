class_name BattlePartyPanel
extends HBoxContainer
## The party cards (bottom right): per hero a PartyCard with the portrait icon, name, HP bar (red to orange) and SP
## bar (blue to cyan) with numbers. The hero waiting for a command gets the brass plate frame. HP shown follows the
## played events, not the sim's finished tick.

var _sim: BattleSim
var _shown_hp: Dictionary[StringName, int]
var _cards: Dictionary[StringName, PartyCard] = {}
var _units: Array[UnitState] = []
var _active: StringName = &""


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_shown_hp = shown_hp
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_right = -view.margin
	offset_bottom = -view.margin
	add_theme_constant_override("separation", Ui.style().size(&"s_pad"))
	for unit: UnitState in sim.timeline.units:
		if unit.side == 0:
			var card: PartyCard = Ui.party_card(unit.def.id)
			_cards[unit.unit_id] = card
			_units.append(unit)
			add_child(card)


func row_count() -> int:
	return _cards.size()


func card_of(unit_id: StringName) -> PartyCard:
	return _cards.get(unit_id)


func active_unit() -> StringName:
	return _active


func _process(_delta: float) -> void:
	if _sim == null:
		return
	var waiting: UnitState = _sim.waiting_hero()
	var now_active: StringName = waiting.unit_id if waiting != null else &""
	for unit: UnitState in _units:
		var card: PartyCard = _cards[unit.unit_id]
		card.update(_shown_hp.get(unit.unit_id, 0), unit.sp)
		if now_active != _active:
			card.set_active(unit.unit_id == now_active)
	_active = now_active
