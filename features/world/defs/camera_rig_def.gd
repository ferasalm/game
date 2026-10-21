class_name CameraRigDef
extends Def
## Camera language for exploring (content/world/camera.json): the opening establishing shot as keyframes (camera
## and target positions relative to the player, field of view, depth-of-field scale, seconds) and the "vista" pose the camera eases to
## inside a vista zone. The ordinary exploring pose is the look's camera_offset / look_height / fov.

## One keyframe of the opening shot. pos and target are offsets from the player.
class Shot extends RefCounted:
	var at: float = 0.0
	var pos: Vector3 = Vector3.ZERO
	var target: Vector3 = Vector3.ZERO
	var fov: float = 30.0
	var dof_scale: float = 1.0

var intro_duration: float = 6.0
var intro_skip_blend: float = 0.4
var keys: Array[Shot] = []
var vista_offset_y: float = 1.7
var vista_offset_z: float = 9.0
var vista_look_height: float = 4.0
var vista_fov: float = 30.0
var vista_dof_scale: float = 1.0
var vista_ease: float = 2.0


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
	for i: int in keys.size():
		if keys[i].at >= intro_duration or (i > 0 and keys[i].at <= keys[i - 1].at):
			r.problem("keys", "key %d: times must rise and stay under intro_duration" % i)
