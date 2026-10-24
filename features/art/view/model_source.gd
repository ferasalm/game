class_name ModelSource
extends VisualSource
## The live 3D source of a CharacterVisual (docs/design/characters-3d.md): a skinned model (ModelRig) or a rigid one
## (RigidRig) from the ModelDef with the sprite's id. Gait clips play at the rate that keeps the feet on the ground
## (speed measured from the body's own movement); one-shots play on the retimed ClipTiming curve and announce &"impact"
## / &"end" on it; the body turns by yaw (never a negative scale), leans into acceleration, freezes on a hit pause.

const RATE_MIN: float = 0.5
const RATE_MAX: float = 2.4
const DUST_BACK: float = 0.3

var def: ModelDef = null
var rig: ModelRig = null
var rigid: RigidRig = null
var trail: WeaponTrail = null
var _weapon := ModelWeapon.new()
var _holder: Node3D
var _clips := ModelClips.new()
var _move := ModelMove.new()
var _state: StringName = &"idle"
var _facing: float = 1.0
var _dir_given: bool = false
var _react := ModelReact.new()


func attach(owner_visual: CharacterVisual, owner_rules: VisualRulesDef) -> void:
	super(owner_visual, owner_rules)
	_holder = Node3D.new()
	visual.body.add_child(_holder)
	_clips.event.connect(_on_event)


## Builds the model with this id (nothing is drawn, and a warning printed, when there is none).
func set_sprite(sprite_id: StringName) -> void:
	def = ContentDB.get_def("model", sprite_id) as ModelDef
	if def == null:
		push_warning("ModelSource: no model '%s'" % sprite_id)
		return
	if def.kind == &"rigid":
		rigid = RigidRig.new()
		rigid.build(def, _holder)
	else:
		rig = ModelRig.new()
		if not rig.build(def, _holder):
			rig = null
			return
		_clips.setup(rig.player)
	_react.setup(visual, rules, materials())
	visual.fx.set_shadow_width(width())
	trail = WeaponTrail.new()
	visual.add_child(trail)
	trail.setup(rules)
	_weapon.setup(rig.hilt if rig != null else null, trail)


func materials() -> Array[ShaderMaterial]:
	if rig != null:
		return rig.materials
	var none: Array[ShaderMaterial] = []
	return rigid.materials if rigid != null else none


func detach() -> void:
	_holder.queue_free()
	if trail != null:
		trail.queue_free()


func set_flip(facing: float) -> void:
	_facing = facing
	if not (_dir_given and signf(sin(_move.target_yaw())) == facing):
		_move.retarget(PI * 0.5 * facing)


func face_dir(dir: Vector3) -> void:
	_dir_given = true
	_move.face(YawTurn.yaw_of(dir, _move.target_yaw()))


func hit_stop(seconds: float) -> void:
	_clips.freeze(seconds)


func update(delta: float, moving: bool, _prop: bool, down: bool, _facing_x: float) -> void:
	if def == null:
		return
	_move.update(delta, visual.global_position + visual.root.position if visual.is_inside_tree() else Vector3.ZERO, def, rules)
	if rig != null:
		_locomote(moving, down)
	_clips.tick(delta)
	if rig != null:
		rig.follow(_clips.current() != null and def.mirrors(_clips.current().id))
	if rigid != null:
		rigid.pose(delta, &"ko" if down else _state, _clips.progress())
	_holder.rotation = Vector3(deg_to_rad(_move.lean), _move.yaw, 0.0)
	visual.body.position.y = visual.lift
	visual.fx.sync(visual.root.position, visual.lift)
	if _move.footfall(delta, def) and visual.is_inside_tree():
		visual.fx.puff(visual.root.position, -signf(sin(_move.yaw)) * DUST_BACK)


func cue(kind: StringName) -> void:
	if def != null and visual.is_inside_tree():
		_react.cue(kind)


func play_clip(state: StringName, _facing_x: float) -> void:
	var clip: ClipDef = _clip(state)
	if clip == null or not visual.is_inside_tree():
		return
	_state = state
	if state == &"attack":
		_weapon.start()
	if clip.loops:
		_clips.play_loop(clip, 1.0)
	else:
		_clips.play_once(clip)


func cast_pose(hold: float) -> void:
	if visual.is_inside_tree():
		await visual.get_tree().create_timer(hold, false).timeout


func hop() -> void:
	if visual.is_inside_tree():
		await _react.hop()


func set_down(down: bool, animate: bool) -> void:
	if def == null or not visual.is_inside_tree():
		return
	var clip: ClipDef = _clip(&"ko")
	if down:
		_state = &"ko"
		if animate and clip != null:
			_clips.play_once(clip)
		elif clip != null and rig != null:
			_clips.pose_at_end(clip)
	else:
		_state = &"idle"
		if animate:
			_react.revive()


func tint_down(share: float) -> void:
	_react.tint_down(share)


func height() -> float:
	return def.height_m if def != null else 0.0


func width() -> float:
	return def.radius * 2.0 * def.girth if def != null else 0.0


func anchor(which: StringName) -> Vector3:
	if def == null:
		return Vector3.ZERO
	var bone := Callable()
	if rig != null and def.anchors.has(String(which)):
		var anchor_id: String = def.anchors[String(which)]
		bone = func() -> Vector3: return _to_root(rig.bone_position(anchor_id))
	return ModelAnchors.point(which, height(), width(), _facing, bone)


func _clip(state: StringName) -> ClipDef:
	if def == null or not def.states.has(String(state)):
		return null
	return ContentDB.get_def("clip", StringName(def.states[String(state)])) as ClipDef


## Picks the looping clip for what the body is doing: still, walking, running; victory dances; a down body stays down.
func _locomote(moving: bool, down: bool) -> void:
	if _clips.busy() or down:
		return
	if visual.state == &"victory":
		_clips.play_loop(_clip(&"victory"), 1.0)
		return
	var gait: StringName = ModelGait.choose(def, _move.speed, moving, visual.state)
	var clip: ClipDef = _clip(gait)
	_clips.play_loop(clip, ModelGait.rate(def, gait, _move.speed, clip.seconds, RATE_MIN, RATE_MAX))


func _on_event(kind: StringName) -> void:
	clip_event.emit(kind)
	if visual.is_inside_tree() and trail != null:
		_weapon.on_event(kind, visual.global_position + visual.root.position + anchor(&"hand"), sin(_move.yaw))


## A point in the model's own space as an offset from the visual's feet (the model, holder and body transforms).
func _to_root(point: Vector3) -> Vector3:
	return visual.body.transform * _holder.transform * rig.model.transform * point
