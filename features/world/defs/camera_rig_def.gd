class_name CameraRigDef
extends Def
## Camera language for exploring (content/world/camera.json): intro shots, presets, limits, and follow/framed modes.

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
var limit_x: Vector2 = Vector2.ZERO
var limit_z: Vector2 = Vector2.ZERO
var mode: StringName = &"fixed"
var follow_distance: float = 6.5
var follow_pitch_deg: float = 28.0
var follow_fov: float = 50.0
var aim_height: float = 1.2
var aim_lead: float = 1.5
var lazy_yaw_delay: float = 0.8
var lazy_yaw_rate: float = 0.6
var walk_toward_dot: float = -0.3
var manual_orbit_speed: float = 1.5
var manual_orbit_pause: float = 2.0
var zone_ease_duration: float = 1.2
var collision_min_distance: float = 2.0
var collision_margin: float = 0.2
var focus_player_weight: float = 0.7
var focus_follower_weight: float = 0.3
var framed_hysteresis: float = 0.5
var framed_clamp_deg: float = 15.0
var stick_retention_deg: float = 20.0
var test_room: CameraRoomDef = null


func read(r: DefReader) -> void:
	id = r.id()
	mode = StringName(r.text("mode", "fixed", false))
	_read_follow_params(r)
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
	if r.has("test_room"):
		test_room = CameraRoomDef.read_from(r.child("test_room"))
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


func _read_follow_params(r: DefReader) -> void:
	follow_distance = r.number("follow_distance", 1.0, 100.0, 6.5, false)
	follow_pitch_deg = r.number("follow_pitch", 0.0, 89.0, 28.0, false)
	follow_fov = r.number("follow_fov", 5.0, 120.0, 50.0, false)
	aim_height = r.number("aim_height", 0.0, 20.0, 1.2, false)
	aim_lead = r.number("aim_lead", 0.0, 20.0, 1.5, false)
	lazy_yaw_delay = r.number("lazy_yaw_delay", 0.0, 10.0, 0.8, false)
	lazy_yaw_rate = r.number("lazy_yaw_rate", 0.0, 10.0, 0.6, false)
	walk_toward_dot = r.number("walk_toward_dot", -1.0, 1.0, -0.3, false)
	manual_orbit_speed = r.number("manual_orbit_speed", 0.1, 10.0, 1.5, false)
	manual_orbit_pause = r.number("manual_orbit_pause", 0.0, 10.0, 2.0, false)
	zone_ease_duration = r.number("zone_ease_duration", 0.1, 10.0, 1.2, false)
	collision_min_distance = r.number("collision_min_distance", 0.1, 20.0, 2.0, false)
	collision_margin = r.number("collision_margin", 0.0, 5.0, 0.2, false)
	focus_player_weight = r.number("focus_player_weight", 0.0, 1.0, 0.7, false)
	focus_follower_weight = r.number("focus_follower_weight", 0.0, 1.0, 0.3, false)
	framed_hysteresis = r.number("framed_hysteresis", 0.0, 10.0, 0.5, false)
	framed_clamp_deg = r.number("framed_clamp_deg", 0.0, 90.0, 15.0, false)
	stick_retention_deg = r.number("stick_retention_deg", 0.0, 90.0, 20.0, false)
