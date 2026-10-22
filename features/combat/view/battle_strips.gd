class_name BattleStrips
extends Control
## The resting vitals of the battle: a slim BattleUnitStrip under each hero's feet (always there) and under a foe
## while it was hit lately or is pointed at (it fades after the view's delay). A hero's strip pulses when its shown
## HP drops. Strips avoid every fighter's rect: they slide sideways if the spot under the feet is taken.

var _sim: BattleSim
var _view: BattleViewDef
var _shown_hp: Dictionary[StringName, int]
var _strips: Dictionary[StringName, BattleUnitStrip] = {}
var _last_hp: Dictionary[StringName, int] = {}
var _idle: Dictionary[StringName, float] = {}  ## foes: seconds since the strip was last asked to show


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_shown_hp = shown_hp
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for unit: UnitState in sim.timeline.units:
		var strip := BattleUnitStrip.new()
		var hero: bool = unit.side == 0
		var initial: String = String(BattleStyle.text(unit.def.name_key)).substr(0, 1) if hero else UnitLetters.of(sim.timeline.units, unit)
		var colour: Color = view.party_color if hero else view.enemy_color
		strip.setup(unit.unit_id, view, initial, unit.def.max_hp, unit.def.max_sp if hero else 0, colour)
		add_child(strip)
		strip.visible = hero
		_strips[unit.unit_id] = strip
		_last_hp[unit.unit_id] = unit.hp
		_idle[unit.unit_id] = INF


func strip_of(unit_id: StringName) -> BattleUnitStrip:
	return _strips.get(unit_id)


## Asks a foe's strip to show (it then fades after the view's delay). Heroes always show.
func reveal(unit_id: StringName) -> void:
	_idle[unit_id] = 0.0


## True while the strip of this unit is on screen.
func shown(unit_id: StringName) -> bool:
	return _strips[unit_id].visible and _strips[unit_id].modulate.a > 0.0


## The screen rects of the strips that show now.
func visible_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for strip: BattleUnitStrip in _strips.values():
		if strip.is_visible_in_tree() and strip.modulate.a > 0.0:
			out.append(strip.get_global_rect())
	return out


func update(delta: float, rects: Dictionary[StringName, Rect2], screen: Rect2) -> void:
	for unit: UnitState in _sim.timeline.units:
		var strip: BattleUnitStrip = _strips[unit.unit_id]
		var hp: int = _shown_hp.get(unit.unit_id, 0)
		if hp < _last_hp[unit.unit_id]:
			_on_hit(unit, strip)
		_last_hp[unit.unit_id] = hp
		strip.set_values(hp, unit.sp)
		_idle[unit.unit_id] += delta
		_fade(unit, strip, hp)
		if strip.visible:
			_place(strip, rects, screen)


func _on_hit(unit: UnitState, strip: BattleUnitStrip) -> void:
	if unit.side == 0:
		strip.pulse()
	else:
		reveal(unit.unit_id)


func _fade(unit: UnitState, strip: BattleUnitStrip, hp: int) -> void:
	if unit.side == 0:
		return
	var alpha: float = HudLayout.fade_alpha(_idle[unit.unit_id], _view.foe_strip_seconds, _view.strip_fade)
	strip.modulate.a = alpha
	strip.visible = alpha > 0.0 and hp > 0


## Under the fighter's feet; the spot beside it when another fighter stands there.
func _place(strip: BattleUnitStrip, rects: Dictionary[StringName, Rect2], screen: Rect2) -> void:
	var own: Rect2 = rects.get(strip.unit_id, Rect2())
	var blockers: Array[Rect2] = []
	for unit_id: StringName in rects:
		if unit_id != strip.unit_id:
			blockers.append(rects[unit_id])
	var size_now: Vector2 = strip.size
	var top: float = own.end.y + _view.strip_gap
	var candidates: Array[Rect2] = []
	for shift: float in [0.0, -0.6, 0.6, -1.2, 1.2]:
		candidates.append(Rect2(Vector2(own.get_center().x - size_now.x / 2.0 + shift * size_now.x, top), size_now))
	strip.position = HudLayout.pick(candidates, blockers, screen).position
