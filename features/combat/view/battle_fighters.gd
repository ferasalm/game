class_name BattleFighters
extends Node3D
## The 3D side of a battle: one CharacterVisual per unit on the stage, floating damage numbers and status text,
## intent labels over casting enemies, and the bouncing target marker. Positions come from the BattleViewDef.
## Keep this node at the world origin (positions are set in world space around the anchor).

var _view: BattleViewDef
var _visuals: Dictionary[StringName, CharacterVisual] = {}
var _intents: Dictionary[StringName, Label3D] = {}
var _marker: MeshInstance3D
var _marker_target: StringName = &""
var _marker_time: float = 0.0


## Party on the left facing right, enemies on the right facing left, around the anchor.
func build(sim: BattleSim, view: BattleViewDef, anchor: Vector3) -> void:
	_view = view
	for unit: UnitState in sim.timeline.units:
		var slots: Array[Vector2] = view.party_stage if unit.side == 0 else view.enemy_stage
		var spot: Vector2 = slots[clampi(unit.slot, 0, slots.size() - 1)]
		var visual := CharacterVisual.new()
		visual.set_sprite(unit.def.id)
		add_child(visual)
		visual.position = anchor + Vector3(spot.x, 0.0, spot.y)
		visual.face(1.0 if unit.side == 0 else -1.0)
		_visuals[unit.unit_id] = visual
	_marker = BattleLabels.marker(view)
	_marker.visible = false
	add_child(_marker)
	set_process(false)


func visual(unit_id: StringName) -> CharacterVisual:
	return _visuals.get(unit_id) as CharacterVisual


func count() -> int:
	return _visuals.size()


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


func float_number(unit_id: StringName, amount: int) -> void:
	_float(unit_id, str(amount), _view.number_font_size, _view.highlight_color)


func float_text(unit_id: StringName, content: String) -> void:
	_float(unit_id, content, _view.text_font_size, _view.party_color)


## A short side-to-side shake. Callers await it.
func shake(unit_id: StringName) -> void:
	var target: CharacterVisual = visual(unit_id)
	if target == null or not is_inside_tree():
		return
	var base: Vector3 = target.position
	var push := Vector3(_view.shake_distance, 0.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(target, "position", base + push, _view.shake_time * 0.25)
	tween.tween_property(target, "position", base - push, _view.shake_time * 0.5)
	tween.tween_property(target, "position", base, _view.shake_time * 0.25)
	await tween.finished


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


func _float(unit_id: StringName, content: String, size: int, color: Color) -> void:
	var target: CharacterVisual = visual(unit_id)
	if target == null or not is_inside_tree():
		return
	var label: Label3D = BattleLabels.floating(content, size, color, _view)
	add_child(label)
	label.position = target.position + Vector3(0.0, target.height(), 0.0)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + _view.number_rise, _view.number_seconds)
	tween.tween_property(label, "modulate:a", 0.0, _view.number_seconds)
	tween.chain().tween_callback(label.queue_free)
