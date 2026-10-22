class_name ModelClips
extends RefCounted
## Drives a MANUAL AnimationPlayer. A looping clip (idle, walk, run) plays at a rate the source sets; a one-shot plays on
## the ClipTiming curve (slow wind-up, a hold, a fast strike, recovery): tick() advances the player slice by slice so
## the pose never drifts off the curve, and `event` announces &"impact" and &"end" from the same curve. freeze() holds
## everything for a hit pause (never Engine.time_scale). Clip data are ClipDefs; the animations are the library's.

signal event(kind: StringName)

var _player: AnimationPlayer
var _once: ClipDef = null
var _elapsed: float = 0.0
var _freeze: float = 0.0
var _loop: ClipDef = null
var _rate: float = 1.0


func setup(player: AnimationPlayer) -> void:
	_player = player


## True while a one-shot is running.
func busy() -> bool:
	return _once != null


func current() -> ClipDef:
	return _once if _once != null else _loop


## Plays a looping clip at `rate` (cross-fading in when it is a different clip than before).
func play_loop(clip: ClipDef, rate: float) -> void:
	_rate = rate
	if clip == _loop and _once == null:
		return
	_once = null
	_loop = clip
	_start(clip)


## Starts a one-shot clip; it announces its events as it runs.
func play_once(clip: ClipDef) -> void:
	_once = clip
	_elapsed = 0.0
	_start(clip)
	for kind: StringName in ClipTiming.events(clip, -1.0, 0.0):
		event.emit(kind)


## Jumps a one-shot to its last pose and holds it (a knocked-out body lying down).
func pose_at_end(clip: ClipDef) -> void:
	_once = null
	_loop = null
	_start(clip)
	if _player != null:
		_player.seek(clip.seconds, true)


## How far the running one-shot is (0..1 of its real time); 1 when none runs.
func progress() -> float:
	return clampf(_elapsed / ClipTiming.total(_once), 0.0, 1.0) if _once != null else 1.0


func freeze(seconds: float) -> void:
	_freeze = maxf(_freeze, seconds)


func is_frozen() -> bool:
	return _freeze > 0.0


func tick(delta: float) -> void:
	var left: float = delta
	if _freeze > 0.0:
		var spent: float = minf(_freeze, left)
		_freeze -= spent
		left -= spent
	if left <= 0.0:
		return
	if _once == null:
		if _player != null:
			_player.speed_scale = _rate
			_player.advance(left)
		return
	var from: float = _elapsed
	_elapsed += left
	for piece: Vector2 in ClipTiming.slices(_once, from, _elapsed):
		if _player != null:
			_player.speed_scale = piece.x
			_player.advance(piece.y)
	var done: ClipDef = _once
	for kind: StringName in ClipTiming.events(done, from, _elapsed):
		if kind == &"end" and _once == done:
			_once = null
			_loop = null  # the next loop starts afresh, whatever it is
		event.emit(kind)


func _start(clip: ClipDef) -> void:
	if _player == null or not _player.has_animation(clip.animation):
		return
	var anim: Animation = _player.get_animation(clip.animation)
	anim.loop_mode = Animation.LOOP_LINEAR if clip.loops else Animation.LOOP_NONE
	_player.play(clip.animation, clip.blend)
	_player.speed_scale = _rate
