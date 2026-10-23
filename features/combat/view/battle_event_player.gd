class_name BattleEventPlayer
extends Node
## Plays a batch of TimelineEvents one after another with the animation each one deserves: the swing and its
## effect (BattleActionPlayer), the flinch, hitstop and popping numbers of a hit, the BREAK! stamp of a cut cast,
## collapses and revives. Pass skip_animation to apply only the state changes (shown HP, intent labels, down poses)
## with no waiting; the call then finishes synchronously.

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
var _extra: BattleEventExtra
var _damage_extra: BattleDamageEvents
## Targets that received a "crit" event for the current action (affects the next damage number display).
var _pending_crit: Dictionary[StringName, bool] = {}


func setup(sim: BattleSim, view: BattleViewDef, fighters: BattleFighters, hud: BattleHud,
		shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_fighters = fighters
	_hud = hud
	_shown_hp = shown_hp
	_extra = BattleEventExtra.new()
	_extra.setup(self)
	_damage_extra = BattleDamageEvents.new()
	add_child(_damage_extra)


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
			var targets: Array[StringName] = BattleEventTargets.targets_after(_sim, events, i)
			await _on_move(event.unit_id, _sim.timeline.find(event.unit_id).acted, targets)
		&"reverse_stab":
			await _on_reverse_stab(event, BattleEventTargets.targets_after(_sim, events, i))
		&"damage":
			await _damage_extra.on_damage(self, event)
		&"missed":
			await _damage_extra.on_missed(self, event)
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
		&"dodged":
			await _extra.on_dodged(event)
		&"crit":
			await _extra.on_crit(event)
		&"resisted":
			await _extra.on_resisted(event)
		&"fled":
			await _extra.on_fled(event)
		&"flee_failed":
			await _extra.on_flee_failed(event)


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
	if target == null:
		return
	if _skip:
		target.set_down(true, false)
	else:
		target.play(&"ko")  # collapses and drains of colour (a model plays its ko clip)


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
		if _skip:
			target.set_down(false, false)
		else:
			target.play(&"idle")  # moving again from ko stands the character back up
	if not _skip:
		_fighters.float_text(event.unit_id, BattleStyle.text("UI_REVIVED"))


func _float_status(event: TimelineEvent, content: String) -> void:
	if not _skip:
		AudioDirector.play_sfx(&"status_apply")
		_fighters.float_text(event.unit_id, content)


func _status_name(status_id: StringName) -> String:
	var status := ContentDB.get_def("status", status_id) as StatusDef
	return BattleStyle.text(status.name_key) if status != null else String(status_id)


func _targets_after(events: Array[TimelineEvent], i: int) -> Array[StringName]:
	return BattleEventTargets.targets_after(_sim, events, i)


func _wait(seconds: float) -> void:
	if not _skip and seconds > 0.0:
		await PauseWait.seconds(self, seconds)
