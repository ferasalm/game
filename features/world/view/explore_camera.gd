class_name ExploreCamera
extends Node
## The exploration camera and its language: it follows the player at the look's offset, eases to a low "vista"
## pose while the player stands in the area's vista zone (so the sky and moon show above the skyline), and can
## play the opening establishing shot (keyframes from CameraRigDef; any key, click or button skips it).
## Rooftop calls update() every frame; nothing else moves the camera while this node is in charge.

## The opening shot ended or was skipped.
signal intro_finished

## Where the camera is and what it looks at.
class Pose extends RefCounted:
	var pos: Vector3 = Vector3.ZERO
	var target: Vector3 = Vector3.ZERO
	var fov: float = 30.0
	## Scale of the look's depth-of-field blur (the sky is far: a lower value keeps its stars sharp).
	var dof: float = 1.0

var _camera: Camera3D
var _rig: CameraRigDef
var _base: CameraRigDef.Preset
var _zone: Rect2 = Rect2()
var _smoothing: float = 6.0
var _focus: Vector3 = Vector3.ZERO
var _vista: float = 0.0
var _intro_time: float = -1.0
var _held: bool = false
var _skip_time: float = -1.0
var _skip_from: Pose = null
var _last: Pose = Pose.new()


## zone: the vista zone on the floor (x, z); focus: where the camera starts looking.
func setup(camera: Camera3D, look: LookDef, rig: CameraRigDef, zone: Rect2, smoothing: float, focus: Vector3) -> void:
	_camera = camera
	_rig = rig
	_base = rig.pose_for(look)
	var attributes := camera.attributes as CameraAttributesPractical
	if attributes != null:
		attributes.dof_blur_near_distance = _base.dof_near
		attributes.dof_blur_far_distance = _base.dof_far
	_zone = zone
	_smoothing = smoothing
	_focus = focus
	_apply(_explore_pose())


func play_intro() -> void:
	if _rig.keys.is_empty():
		return
	_intro_time = 0.0
	_skip_time = -1.0
	_apply(_intro_pose(0.0))


## While held, the opening shot waits on its first frame (the moon) and key presses do not skip it. A title
## overlay holds it until the player presses a key, then releases it.
func hold_intro(on: bool) -> void:
	_held = on


func is_intro_held() -> bool:
	return _held


func is_intro_playing() -> bool:
	return _intro_time >= 0.0


## 0 = ordinary exploring pose, 1 = fully in the vista pose.
func vista_amount() -> float:
	return _vista


## Ends the opening shot; the camera eases from where it is to the exploring pose (at once when instant).
func skip_intro(instant: bool = false) -> void:
	if not is_intro_playing():
		return
	_intro_time = -1.0
	if not instant and _rig.intro_skip_blend > 0.0:
		_skip_from = _last
		_skip_time = 0.0
	intro_finished.emit()


## Moves the camera one frame: the focus trails the subject, the vista blend follows the zone.
func update(delta: float, subject: Vector3) -> void:
	_focus = _focus.lerp(subject, 1.0 - exp(-_smoothing * delta))
	var inside: float = 1.0 if _zone.has_point(Vector2(subject.x, subject.z)) else 0.0
	_vista = lerpf(_vista, inside, 1.0 - exp(-_rig.vista_ease * delta))
	var pose: Pose = _explore_pose()
	if is_intro_playing():
		_intro_time += 0.0 if _held else delta
		if _intro_time >= _rig.intro_duration:
			_intro_time = -1.0
			intro_finished.emit()
		else:
			pose = _intro_pose(_intro_time)
	if _skip_time >= 0.0:
		_skip_time += delta
		var weight: float = smoothstep(0.0, 1.0, _skip_time / _rig.intro_skip_blend)
		pose = _mix(_skip_from, pose, weight)
		if weight >= 1.0:
			_skip_time = -1.0
	_apply(pose)


func _unhandled_input(event: InputEvent) -> void:
	if is_intro_playing() and not _held and _is_press(event):
		skip_intro()
		get_viewport().set_input_as_handled()


func _is_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return (event as InputEventKey).pressed and not (event as InputEventKey).echo
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	return event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed


func _explore_pose() -> Pose:
	var pose := Pose.new()
	var vista_offset := Vector3(0.0, _rig.vista_offset_y, _rig.vista_offset_z)
	pose.pos = _focus + _base.offset.lerp(vista_offset, _vista)
	pose.target = _focus + Vector3(0.0, lerpf(_base.look_height, _rig.vista_look_height, _vista), 0.0)
	pose.fov = lerpf(_base.fov, _rig.vista_fov, _vista)
	pose.dof = lerpf(1.0, _rig.vista_dof_scale, _vista)
	return pose


## The opening shot at time t: Catmull-Rom through the keys, ending on the ordinary exploring pose.
func _intro_pose(t: float) -> Pose:
	var keys: Array[CameraRigDef.Shot] = _rig.keys.duplicate()
	var last := CameraRigDef.Shot.new()
	last.at = _rig.intro_duration
	last.pos = _base.offset
	last.target = Vector3(0.0, _base.look_height, 0.0)
	last.fov = _base.fov
	last.dof_scale = 1.0
	keys.append(last)
	var i: int = 0
	while i < keys.size() - 2 and t >= keys[i + 1].at:
		i += 1
	var a: CameraRigDef.Shot = keys[i]
	var b: CameraRigDef.Shot = keys[i + 1]
	var before: CameraRigDef.Shot = keys[maxi(i - 1, 0)]
	var after: CameraRigDef.Shot = keys[mini(i + 2, keys.size() - 1)]
	var w: float = clampf((t - a.at) / maxf(b.at - a.at, 0.001), 0.0, 1.0)
	var pose := Pose.new()
	pose.pos = _focus + a.pos.cubic_interpolate(b.pos, before.pos, after.pos, w)
	pose.target = _focus + a.target.cubic_interpolate(b.target, before.target, after.target, w)
	var ease_w: float = smoothstep(0.0, 1.0, w)
	pose.fov = lerpf(a.fov, b.fov, ease_w)
	pose.dof = lerpf(a.dof_scale, b.dof_scale, ease_w)
	return pose


func _mix(from: Pose, to: Pose, weight: float) -> Pose:
	var pose := Pose.new()
	pose.pos = from.pos.lerp(to.pos, weight)
	pose.target = from.target.lerp(to.target, weight)
	pose.fov = lerpf(from.fov, to.fov, weight)
	pose.dof = lerpf(from.dof, to.dof, weight)
	return pose


func _apply(pose: Pose) -> void:
	_last = pose
	_camera.position = pose.pos
	_camera.look_at(pose.target)
	_camera.fov = pose.fov
	(_camera.attributes as CameraAttributesPractical).dof_blur_amount = _base.dof_amount * pose.dof
