class_name BattleEventPlayer
extends Node
## Plays a batch of TimelineEvents one after another with the animation each one deserves (lunge, flash and
## rising number, banner and hit-stop, shake, status text, knocked out). Pass skip_animation to apply only the
## state changes (shown HP, intent labels, down poses) with no waiting; the call then finishes synchronously.

var _sim: BattleSim
var _view: BattleViewDef
var _fighters: BattleFighters
var _hud: BattleHud
var _shown_hp: Dictionary[StringName, int]
var _skip: bool = false


func setup(sim: BattleSim, view: BattleViewDef, fighters: BattleFighters, hud: BattleHud,
		shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_fighters = fighters
	_hud = hud
	_shown_hp = shown_hp


func play(events: Array[TimelineEvent], skip_animation: bool) -> void:
	_skip = skip_animation
	for i: int in events.size():
		await _play_one(events, i)


func _play_one(events: Array[TimelineEvent], i: int) -> void:
	var event: TimelineEvent = events[i]
	match event.kind:
		&"command":
			_on_command(event)
		&"act":
			_fighters.clear_intent(event.unit_id)
			await _lunge(event.unit_id, _next_target(events, i))
		&"reverse_stab":
			await _on_reverse_stab(event, _next_target(events, i))
		&"damage":
			await _on_damage(event)
		&"interrupted":
			_fighters.clear_intent(event.unit_id)
			await _on_interrupted()
		&"knocked_back":
			if not _skip:
				await _fighters.shake(event.unit_id)
		&"status":
			_float_status(event, _status_name(event.detail))
		&"status_ended":
			_float_status(event, BattleStyle.text("UI_STATUS_ENDED") % _status_name(event.detail))
		&"down":
			_on_down(event)
		&"healed":
			_on_healed(event)
		&"revived":
			_on_revived(event)


func _on_command(event: TimelineEvent) -> void:
	var unit: UnitState = _sim.timeline.find(event.unit_id)
	if unit == null or unit.side != 1 or unit.action == null:
		return
	_fighters.show_intent(unit.unit_id, BattleStyle.text(unit.action.name_key))
	_hud.show_tip(&"tip_charge_seen", "UI_TIP_CHARGE")


func _on_reverse_stab(event: TimelineEvent, target_id: StringName) -> void:
	if not _skip:
		_hud.show_banner(BattleStyle.text("UI_REVERSE_STAB"))
		await _wait(_view.banner_seconds * 0.5)
	var stabber: CharacterVisual = _fighters.visual(event.unit_id)
	if stabber != null:
		stabber.face(1.0)
	await _lunge(event.unit_id, target_id)


func _on_damage(event: TimelineEvent) -> void:
	var before: int = _shown_hp.get(event.unit_id, 0)
	_shown_hp[event.unit_id] = maxi(0, before - event.value)
	if _skip:
		return
	var target: CharacterVisual = _fighters.visual(event.unit_id)
	if target != null:
		target.flash()
	_fighters.float_number(event.unit_id, event.value)
	await _wait(_view.damage_gap)


func _on_interrupted() -> void:
	if _skip:
		return
	_hud.show_banner(BattleStyle.text("UI_INTERRUPTED"))
	await _wait(_view.hit_stop)


func _on_down(event: TimelineEvent) -> void:
	_shown_hp[event.unit_id] = 0
	_fighters.clear_intent(event.unit_id)
	var target: CharacterVisual = _fighters.visual(event.unit_id)
	if target != null:
		target.set_down(true)


func _on_healed(event: TimelineEvent) -> void:
	var unit: UnitState = _sim.timeline.find(event.unit_id)
	_shown_hp[event.unit_id] = mini(unit.def.max_hp, _shown_hp.get(event.unit_id, 0) + event.value)
	if not _skip:
		_fighters.float_text(event.unit_id, BattleStyle.text("UI_HEALED") % event.value)


func _on_revived(event: TimelineEvent) -> void:
	var target: CharacterVisual = _fighters.visual(event.unit_id)
	if target != null:
		target.set_down(false)
	if not _skip:
		_fighters.float_text(event.unit_id, BattleStyle.text("UI_REVIVED"))


func _float_status(event: TimelineEvent, content: String) -> void:
	if not _skip:
		_fighters.float_text(event.unit_id, content)


func _status_name(status_id: StringName) -> String:
	var status := ContentDB.get_def("status", status_id) as StatusDef
	return BattleStyle.text(status.name_key) if status != null else String(status_id)


func _lunge(actor_id: StringName, target_id: StringName) -> void:
	if _skip or target_id == &"":
		return
	var actor: CharacterVisual = _fighters.visual(actor_id)
	var target: CharacterVisual = _fighters.visual(target_id)
	if actor != null and target != null:
		await actor.lunge(target.global_position)


## The first unit hit after events[i] (before the next act): who the actor lunges toward.
func _next_target(events: Array[TimelineEvent], i: int) -> StringName:
	for j: int in range(i + 1, events.size()):
		if events[j].kind == &"damage":
			return events[j].unit_id
		if events[j].kind == &"act" or events[j].kind == &"reverse_stab":
			break
	return &""


func _wait(seconds: float) -> void:
	if not _skip and seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
