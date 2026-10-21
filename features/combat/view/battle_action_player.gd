class_name BattleActionPlayer
extends Node
## Plays the swing of one move: the camera leans toward the actor, a melee actor anticipates and dashes (a caster
## crouches and rises), the move's effect plays, and the call returns when the hit lands. The hit itself
## (flash, knockback, shake, hitstop) comes from `on_hit`, once per damage event.

var _fighters: BattleFighters
var _vfx: VfxPlayer
var _camera: BattleCamera
var _juice: BattleJuice
var _pending: VfxDef
var _actor: CharacterVisual
var _hit_done: bool = false
var _settled: bool = true


func setup(fighters: BattleFighters, vfx: VfxPlayer, camera: BattleCamera, juice: BattleJuice) -> void:
	_fighters = fighters
	_vfx = vfx
	_camera = camera
	_juice = juice


## The effect an action plays: its own kind, else slash (melee) or bolt (ranged).
func vfx_for(action: ActionDef) -> VfxDef:
	var kind: StringName = action.vfx if action.vfx != &"" else (&"slash" if action.is_melee else &"bolt")
	return ContentDB.get_def("vfx", kind) as VfxDef


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
	_hit_done = false
	_settled = false
	_camera.focus_on(actor.global_position.x)
	_camera.push(def.zoom, def.impact + 0.5)
	if action.is_melee and action.is_hostile() and not targets.is_empty():
		var spot: Vector3 = targets[0].global_position
		await actor.anticipate(spot)
		await actor.dash(spot)
	else:
		actor.cast_pose(_juice.def.cast_hold)
	_vfx.play(def, actor, targets)
	if not action.is_hostile():
		AudioDirector.play_action(action)
	await get_tree().create_timer(def.impact).timeout
	if not action.is_hostile() or targets.is_empty():
		settle()


## A damage event lands on `target`: it flinches away from the attacker; the first hit shakes and freezes.
func on_hit(target: CharacterVisual) -> void:
	var def: VfxDef = _pending
	var push: float = 0.0
	if def != null and _actor != null:
		push = signf(target.global_position.x - _actor.global_position.x) * def.knock
	target.hurt(push)
	if def == null or _hit_done:
		return
	_hit_done = true
	_juice.shake(def.shake)
	await _juice.hitstop(def.hitstop)
	settle()


## The move is over: the actor walks home and the camera lets go.
func settle() -> void:
	if _settled:
		return
	_settled = true
	if _actor != null:
		_actor.return_home()
	_camera.clear_focus()
