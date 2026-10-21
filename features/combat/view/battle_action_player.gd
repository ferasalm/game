class_name BattleActionPlayer
extends Node
## Plays the swing of one move: the camera leans toward the actor, the actor plays its clip (attack, cast or item)
## while a melee actor anticipates and dashes, and the call returns when the CLIP says the hit lands (its `impact`
## event, never a timer; a ranged move then waits out its effect's flight). The hit itself (flash, knockback, shake,
## the hit pause on both fighters) comes from `on_hit`, once per damage event. Spacing comes from the models' widths.

var _fighters: BattleFighters
var _vfx: VfxPlayer
var _camera: BattleCamera
var _juice: BattleJuice
var _pending: VfxDef
var _actor: CharacterVisual
var _actor_id: StringName = &""
var _hit_done: bool = false
var _settled: bool = true
var _waiting: bool = false


func setup(fighters: BattleFighters, vfx: VfxPlayer, camera: BattleCamera, juice: BattleJuice) -> void:
	_fighters = fighters
	_vfx = vfx
	_camera = camera
	_juice = juice


## The effect an action plays: its own kind, else slash (melee) or bolt (ranged).
func vfx_for(action: ActionDef) -> VfxDef:
	var kind: StringName = action.vfx if action.vfx != &"" else (&"slash" if action.is_melee else &"bolt")
	return ContentDB.get_def("vfx", kind) as VfxDef


## True while the move waits for its actor's impact event (a test reads it).
func is_waiting_for_impact() -> bool:
	return _waiting


## Everything up to the moment of impact. `target_ids` may be empty (nothing to hit).
func begin(actor_id: StringName, action: ActionDef, target_ids: Array[StringName]) -> void:
	settle()
	var actor: CharacterVisual = _fighters.visual(actor_id)
	var def: VfxDef = vfx_for(action) if action != null else null
	if actor == null or def == null:
		return
	var targets: Array[CharacterVisual] = []
	for target_id: StringName in target_ids:
		if _fighters.visual(target_id) != null:
			targets.append(_fighters.visual(target_id))
	_pending = def
	_actor = actor
	_actor_id = actor_id
	_hit_done = false
	_settled = false
	_camera.focus_on(actor.global_position.x)
	_camera.push(def.zoom, def.impact + 0.5)
	var melee: bool = action.is_melee and action.is_hostile() and not targets.is_empty()
	var state: StringName = &"attack" if melee else (&"item" if action is ItemAction else &"cast")
	var clip := ClipWait.new(actor)
	actor.play(state)
	if melee:
		_lunge(actor, targets[0])
	else:
		actor.cast_pose(_juice.def.cast_hold)
	_waiting = true
	await clip.until(&"impact", self, _juice.def.clip_timeout)
	_waiting = false
	clip.release()
	if action is ItemAction and targets.is_empty():
		settle()  # a herb that fizzled shows no effect, only its "no effect" text
		return
	_vfx.play(def, actor, targets)
	if not action.is_hostile():
		AudioDirector.play_action(action)
	if not melee:
		await PauseWait.seconds(self, def.impact)  # a bolt's flight: the clip's impact is its release
	if not action.is_hostile() or targets.is_empty():
		settle()


## A damage event lands on `target`: it flinches away from the attacker; both freeze a moment; the first hit
## shakes the camera and freezes the whole frame. `amount` picks the light or heavy pause.
func on_hit(target: CharacterVisual, amount: int = 0) -> void:
	var def: VfxDef = _pending
	var push: float = 0.0
	if def != null and _actor != null:
		push = signf(target.global_position.x - _actor.global_position.x) * def.knock
	target.play(&"hurt")
	target.hurt(push)  # the push of this move replaces the clip's default flinch slide
	var pause: float = _juice.def.hit_pause_heavy if amount >= _juice.def.heavy_damage else _juice.def.hit_pause
	target.hit_stop(pause)
	if _actor != null:
		_actor.hit_stop(pause)
	if def == null or _hit_done:
		return
	_hit_done = true
	_juice.shake(def.shake)
	await _juice.hitstop(def.hitstop)
	settle()


## The move is over: the actor walks home, turns back to its foes and the camera lets go.
func settle() -> void:
	if _settled:
		return
	_settled = true
	if _actor != null:
		_actor.return_home()
		_fighters.face_foes(_actor_id)
	_camera.clear_focus()


## Anticipate and dash to just short of the target (their widths and the contact gap keep them apart). Runs on its
## own: the move waits for the clip's impact, not for the dash.
func _lunge(actor: CharacterVisual, target: CharacterVisual) -> void:
	var spot: Vector3 = _contact_spot(actor, target)
	await actor.anticipate(spot)
	await actor.dash(spot)


func _contact_spot(actor: CharacterVisual, target: CharacterVisual) -> Vector3:
	var gap: float = (actor.width() + target.width()) * 0.5 + _juice.def.contact_gap
	var flat: Vector3 = target.global_position - actor.global_position
	flat.y = 0.0
	if flat.length() <= gap:
		return actor.global_position
	return target.global_position - flat.normalized() * gap
