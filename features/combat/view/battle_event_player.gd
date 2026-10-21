class_name BattleEventPlayer
extends Node
## Plays a batch of TimelineEvents one after another with the animation each one deserves: the swing and its
## effect (BattleActionPlayer), the flinch, hitstop and popping numbers of a hit, the BREAK! stamp of a cut cast,
## collapses and revives. Pass skip_animation to apply only the state changes (shown HP, intent labels, down poses)
## with no waiting; the call then finishes synchronously.

const MOVE_KINDS: Array[StringName] = [&"act", &"reverse_stab", &"command"]
const TARGET_KINDS: Array[StringName] = [&"damage", &"healed", &"status", &"revived", &"sp_restored"]
const BREAK_VFX: StringName = &"break"

var _sim: BattleSim
var _view: BattleViewDef
var _fighters: BattleFighters
var _hud: BattleHud
var _shown_hp: Dictionary[StringName, int]
var _skip: bool = false
var _actions: BattleActionPlayer
var _juice: BattleJuice
var _vfx: VfxPlayer


func setup(sim: BattleSim, view: BattleViewDef, fighters: BattleFighters, hud: BattleHud,
		shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_fighters = fighters
	_hud = hud
	_shown_hp = shown_hp


## The pieces that make the show: the move player, the hitstop / shake node and the effect painter.
func attach(actions: BattleActionPlayer, juice: BattleJuice, vfx: VfxPlayer) -> void:
	_actions = actions
	_juice = juice
	_vfx = vfx


func play(events: Array[TimelineEvent], skip_animation: bool) -> void:
	_skip = skip_animation
	for i: int in events.size():
		await _play_one(events, i)
	if not _skip:
		_actions.settle()


func _play_one(events: Array[TimelineEvent], i: int) -> void:
	var event: TimelineEvent = events[i]
	match event.kind:
		&"command":
			_on_command(event)
		&"act":
			_fighters.clear_intent(event.unit_id)
			await _on_move(event.unit_id, _sim.timeline.find(event.unit_id).acted, _targets_after(events, i))
		&"reverse_stab":
			await _on_reverse_stab(event, _targets_after(events, i))
		&"damage":
			await _on_damage(event)
		&"interrupted":
			await _on_interrupted(event)
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
		&"sp_restored":
			_on_sp_restored(event)
		&"fizzled":
			_float_status(event, BattleStyle.text("BATTLE_ITEM_FIZZLED"))


func _on_command(event: TimelineEvent) -> void:
	var unit: UnitState = _sim.timeline.find(event.unit_id)
	if unit == null or unit.side != 1 or unit.action == null:
		return
	_fighters.show_intent(unit.unit_id, BattleStyle.text(unit.action.name_key))
	_hud.show_tip(&"tip_charge_seen", "UI_TIP_CHARGE")


func _on_reverse_stab(event: TimelineEvent, targets: Array[StringName]) -> void:
	if not _skip:
		_hud.show_banner(BattleStyle.text("UI_REVERSE_STAB"))
		await _wait(_view.banner_seconds * 0.5)
	_fighters.face_foes(event.unit_id)
	await _on_move(event.unit_id, _sim.actions.get(event.detail) as ActionDef, targets)


func _on_move(actor_id: StringName, action: ActionDef, targets: Array[StringName]) -> void:
	if not _skip and action != null:
		await _actions.begin(actor_id, action, targets)


func _on_damage(event: TimelineEvent) -> void:
	var before: int = _shown_hp.get(event.unit_id, 0)
	_shown_hp[event.unit_id] = maxi(0, before - event.value)
	if _skip:
		return
	AudioDirector.play_hit(_sim.actions.get(event.detail) as ActionDef, event.value)
	var target: CharacterVisual = _fighters.visual(event.unit_id)
	if target != null:
		_fighters.float_number(event.unit_id, event.value)
		await _actions.on_hit(target)
	await _wait(_view.damage_gap)


## The cut cast: BREAK! stamp, a burst, a hard freeze and a camera jolt.
func _on_interrupted(event: TimelineEvent) -> void:
	_fighters.clear_intent(event.unit_id)
	if _skip:
		return
	AudioDirector.play_sfx(&"interrupt")
	var target: CharacterVisual = _fighters.visual(event.unit_id)
	if target != null:
		_fighters.show_break(event.unit_id)
		_vfx.play(ContentDB.get_def("vfx", BREAK_VFX) as VfxDef, target, [] as Array[CharacterVisual])
	_juice.shake(_juice.def.break_shake)
	await _juice.hitstop(_juice.def.break_hitstop)
	await _wait(_view.hit_stop * 0.4)


func _on_down(event: TimelineEvent) -> void:
	_shown_hp[event.unit_id] = 0
	if not _skip:
		AudioDirector.play_sfx(&"knock_out")
	_fighters.clear_intent(event.unit_id)
	var target: CharacterVisual = _fighters.visual(event.unit_id)
	if target != null:
		target.set_down(true, not _skip)


func _on_healed(event: TimelineEvent) -> void:
	var unit: UnitState = _sim.timeline.find(event.unit_id)
	_shown_hp[event.unit_id] = mini(unit.def.max_hp, _shown_hp.get(event.unit_id, 0) + event.value)
	if not _skip:
		_fighters.float_heal(event.unit_id, BattleStyle.text("UI_HEALED") % event.value)


func _on_sp_restored(event: TimelineEvent) -> void:
	if not _skip:
		_fighters.float_heal(event.unit_id, BattleStyle.text("BATTLE_SP_RESTORED") % event.value)


func _on_revived(event: TimelineEvent) -> void:
	var target: CharacterVisual = _fighters.visual(event.unit_id)
	if target != null:
		target.set_down(false, not _skip)
	if not _skip:
		_fighters.float_text(event.unit_id, BattleStyle.text("UI_REVIVED"))


func _float_status(event: TimelineEvent, content: String) -> void:
	if not _skip:
		AudioDirector.play_sfx(&"status_apply")
		_fighters.float_text(event.unit_id, content)


func _status_name(status_id: StringName) -> String:
	var status := ContentDB.get_def("status", status_id) as StatusDef
	return BattleStyle.text(status.name_key) if status != null else String(status_id)


## Who the move after events[i] touches: the units named by its hit, heal and status events (until the next move).
func _targets_after(events: Array[TimelineEvent], i: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for j: int in range(i + 1, events.size()):
		var next: TimelineEvent = events[j]
		if MOVE_KINDS.has(next.kind):
			break
		if TARGET_KINDS.has(next.kind) and next.detail != &"regen" and not out.has(next.unit_id):
			out.append(next.unit_id)
	return out


func _wait(seconds: float) -> void:
	if not _skip and seconds > 0.0:
		await PauseWait.seconds(self, seconds)
