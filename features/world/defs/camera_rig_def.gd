class_name CameraRigDef
extends Def
## Camera language for exploring (content/world/camera.json): the opening establishing shot as keyframes (camera
## and target positions relative to the player, field of view, depth-of-field scale, seconds) and the "vista" pose the camera eases to
## inside a vista zone. The ordinary exploring pose is the look's camera_offset / look_height / fov, or one of the
## named presets (a look's camera_preset): pitch down to the target, distance, field of view and its own depth of field.

## One keyframe of the opening shot. pos and target are offsets from the player.
class Shot extends RefCounted:
	var at: float = 0.0
	var pos: Vector3 = Vector3.ZERO
	var target: Vector3 = Vector3.ZERO
	var fov: float = 30.0
	var dof_scale: float = 1.0

## The ordinary exploring pose: camera offset from the player, look height, field of view and depth of field.
class Preset extends RefCounted:
	var offset: Vector3 = Vector3.ZERO
	var look_height: float = 0.8
	var fov: float = 30.0
	var dof_near: float = 5.0
	var dof_far: float = 12.0
	var dof_amount: float = 0.1

	static func from_look(look: LookDef) -> Preset:
		var p := Preset.new()
		p.offset = look.camera_offset
		p.look_height = look.look_height
		p.fov = look.fov
		p.dof_near = look.dof_near
		p.dof_far = look.dof_far
		p.dof_amount = look.dof_amount
		return p

var intro_duration: float = 6.0
var intro_skip_blend: float = 0.4
var keys: Array[Shot] = []
var vista_offset_y: float = 1.7
var vista_offset_z: float = 9.0
var vista_look_height: float = 4.0
var vista_fov: float = 30.0
var vista_dof_scale: float = 1.0
var vista_ease: float = 2.0
var presets: Dictionary[StringName, Preset] = {}
## Where the camera target may go (x range and z range, metres); the player can walk past it, the frame stays put.
## (0, 0) for both = no limits.
var limit_x: Vector2 = Vector2.ZERO
var limit_z: Vector2 = Vector2.ZERO


func read(r: DefReader) -> void:
	id = r.id()
	intro_duration = r.number("intro_duration", 0.5, 60.0)
	intro_skip_blend = r.number("intro_skip_blend", 0.0, 5.0)
	for kr: DefReader in r.objects("keys"):
		var key := Shot.new()
		key.at = kr.number("at", 0.0, 60.0)
		key.pos = Vector3(kr.number("px", -100.0, 100.0), kr.number("py", -10.0, 100.0), kr.number("pz", -100.0, 100.0))
		key.target = Vector3(kr.number("tx", -200.0, 200.0), kr.number("ty", -200.0, 200.0),
			kr.number("tz", -200.0, 200.0))
		key.fov = kr.number("fov", 5.0, 120.0)
		key.dof_scale = kr.number("dof", 0.0, 4.0)
		keys.append(key)
	vista_offset_y = r.number("vista_offset_y", -5.0, 50.0)
	vista_offset_z = r.number("vista_offset_z", 0.5, 50.0)
	vista_look_height = r.number("vista_look_height", -5.0, 50.0)
	vista_fov = r.number("vista_fov", 5.0, 120.0)
	vista_dof_scale = r.number("vista_dof", 0.0, 4.0)
	vista_ease = r.number("vista_ease", 0.1, 20.0)
	for pr: DefReader in r.optional_objects("presets"):
		presets[pr.id()] = _read_preset(pr)
	_read_limits(r)
	for i: int in keys.size():
		if keys[i].at >= intro_duration or (i > 0 and keys[i].at <= keys[i - 1].at):
			r.problem("keys", "key %d: times must rise and stay under intro_duration" % i)


func has_limits() -> bool:
	return limit_x != Vector2.ZERO or limit_z != Vector2.ZERO


func _read_limits(r: DefReader) -> void:
	if not r.has("limits"):
		return
	var lr: DefReader = r.child("limits")
	var xs: Array[float] = lr.float_list("x", -500.0, 500.0)
	var zs: Array[float] = lr.float_list("z", -500.0, 500.0)
	if xs.size() != 2 or zs.size() != 2 or xs[0] > xs[1] or zs[0] > zs[1]:
		r.problem("limits", "needs x and z as [min, max]")
		return
	limit_x = Vector2(xs[0], xs[1])
	limit_z = Vector2(zs[0], zs[1])


## The exploring pose for a look: its camera_preset when it names one of ours, else the look's own numbers.
func pose_for(look: LookDef) -> Preset:
	return presets.get(look.camera_preset, Preset.from_look(look)) as Preset


func _read_preset(r: DefReader) -> Preset:
	var p := Preset.new()
	var pitch: float = deg_to_rad(r.number("pitch", 5.0, 89.0))
	var distance: float = r.number("distance", 1.0, 100.0)
	p.look_height = r.number("look_height", 0.0, 5.0)
	p.offset = Vector3(0.0, p.look_height + sin(pitch) * distance, cos(pitch) * distance)
	p.fov = r.number("fov", 5.0, 120.0)
	p.dof_near = r.number("dof_near", 0.0, 100.0)
	p.dof_far = r.number("dof_far", 0.0, 200.0)
	p.dof_amount = r.number("dof_amount", 0.0, 1.0)
	return p
