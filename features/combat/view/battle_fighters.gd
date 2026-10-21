class_name BattleFighters
extends Node3D
## The 3D side of a battle: one CharacterVisual per unit on the stage, popping damage / heal numbers and status
## text, the BREAK! stamp, intent labels over casting enemies, and the bouncing target marker. Positions come from
## the BattleViewDef. Keep this node at the world origin (positions are set in world space around the anchor).

var _view: BattleViewDef
var _juice: JuiceDef
var _visuals: Dictionary[StringName, CharacterVisual] = {}
var _party: Array[StringName] = []
var _intents: Dictionary[StringName, Label3D] = {}
var _marker: MeshInstance3D
var _marker_target: StringName = &""
var _marker_time: float = 0.0
var _rng := RandomNumberGenerator.new()


## Party on the left facing right, enemies on the right facing left, around the anchor.
func build(sim: BattleSim, view: BattleViewDef, anchor: Vector3) -> void:
	_view = view
	_juice = ContentDB.get_def("battle_juice", &"default") as JuiceDef
	if _juice == null:
		_juice = JuiceDef.new()
	_rng.seed = 3
	for unit: UnitState in sim.timeline.units:
		var slots: Array[Vector2] = view.party_stage if unit.side == 0 else view.enemy_stage
		var spot: Vector2 = slots[clampi(unit.slot, 0, slots.size() - 1)]
		var visual := CharacterVisual.new()
		visual.set_sprite(unit.def.id)
		add_child(visual)
		visual.position = anchor + Vector3(spot.x, 0.0, spot.y)
		visual.face(1.0 if unit.side == 0 else -1.0)
		_visuals[unit.unit_id] = visual
		if unit.side == 0:
			_party.append(unit.unit_id)
	_marker = BattleLabels.marker(view)
	_marker.visible = false
	add_child(_marker)
	set_process(false)


func visual(unit_id: StringName) -> CharacterVisual:
	return _visuals.get(unit_id) as CharacterVisual


func count() -> int:
	return _visuals.size()


## The party members still standing hop for joy.
func cheer() -> void:
	for unit_id: StringName in _party:
		var hero: CharacterVisual = visual(unit_id)
		if hero != null and not hero.is_down():
			hero.victory_hop()


func show_intent(unit_id: StringName, content: String) -> void:
	clear_intent(unit_id)
	var target: CharacterVisual = visual(unit_id)
	if target == null:
		return
	var label: Label3D = BattleLabels.floating(content, _view.text_font_size, _view.enemy_color, _view)
	target.add_child(label)
	label.position = Vector3(0.0, target.height() + _view.intent_offset, 0.0)
	_intents[unit_id] = label


func clear_intent(unit_id: StringName) -> void:
	var label: Label3D = _intents.get(unit_id) as Label3D
	if label != null:
		label.queue_free()
	_intents.erase(unit_id)


func intent_text(unit_id: StringName) -> String:
	var label: Label3D = _intents.get(unit_id) as Label3D
	return label.text if label != null else ""


## A damage number: pops, bounces, bigger and hotter for a heavy hit.
func float_number(unit_id: StringName, amount: int) -> void:
	var heavy: bool = amount >= _juice.heavy_damage
	_pop(unit_id, str(amount), _view.number_font_size, _juice.break_color if heavy else _juice.damage_color,
		_juice.heavy_scale if heavy else 1.0)


## A heal number (green).
func float_heal(unit_id: StringName, content: String) -> void:
	_pop(unit_id, content, _view.number_font_size, _juice.heal_color, 1.0)


func float_text(unit_id: StringName, content: String) -> void:
	_pop(unit_id, content, _view.text_font_size, _view.party_color, 1.0)


## The BREAK! stamp over a unit whose cast was cut.
func show_break(unit_id: StringName) -> void:
	var target: CharacterVisual = visual(unit_id)
	if target != null and is_inside_tree():
		BattleNumbers.stamp(self, BattleStyle.text("UI_BREAK"), _head(target, 0.3), _view, _juice)


func point_at(unit_id: StringName) -> void:
	_marker_target = unit_id
	_marker.visible = visual(unit_id) != null
	set_process(_marker.visible)
	_place_marker()


func hide_marker() -> void:
	_marker_target = &""
	_marker.visible = false
	set_process(false)


func marker_target() -> StringName:
	return _marker_target if _marker.visible else &""


func _process(delta: float) -> void:
	_marker_time += delta * _view.marker_speed
	_place_marker()


func _place_marker() -> void:
	var target: CharacterVisual = visual(_marker_target)
	if target == null:
		return
	var bounce: float = absf(sin(_marker_time)) * _view.marker_bounce
	_marker.position = target.position + Vector3(0.0, target.height() + _view.marker_offset + bounce, 0.0)


func _pop(unit_id: StringName, content: String, size: int, color: Color, size_factor: float) -> void:
	var target: CharacterVisual = visual(unit_id)
	if target == null or not is_inside_tree():
		return
	BattleNumbers.pop(self, content, _head(target, 0.0), size, color, size_factor, _view, _juice,
		_rng.randf_range(-1.0, 1.0))


func _head(target: CharacterVisual, extra: float) -> Vector3:
	return target.position + Vector3(0.0, target.height() + extra, 0.0)
