class_name Locomotion
extends RefCounted
## Pure walking maths for a model: which gait a ground speed means, the playback rate that keeps feet from sliding
## (speed / stride), a smoothed speed and the lean into acceleration. No nodes here.


## &"idle", &"walk" or &"run" for a speed (m/s). `was_moving` keeps a gait a little longer (no flicker at the edge).
static func gait(speed: float, idle_speed: float, run_speed: float, was_moving: bool = false) -> StringName:
	var floor_speed: float = idle_speed * (0.5 if was_moving else 1.0)
	if speed <= floor_speed:
		return &"idle"
	return &"run" if speed >= run_speed else &"walk"


## Playback rate of a looping gait clip so the feet keep pace with the ground: `stride_m` is the distance one full
## cycle covers at rate 1, `clip_seconds` the cycle's length. Clamped to lo..hi.
static func playback_rate(speed: float, stride_m: float, clip_seconds: float, lo: float, hi: float) -> float:
	if stride_m <= 0.0:
		return 1.0
	return clampf(speed * clip_seconds / stride_m, lo, hi)


## Exponential smoothing of a measured value toward a new sample.
static func smooth(current: float, sample: float, delta: float, rate: float) -> float:
	return lerpf(current, sample, 1.0 - exp(-rate * delta))


## The lean (degrees, signed) of a body that accelerates by `accel` m/s^2 along its facing, at most `max_degrees`.
static func lean(accel: float, per_accel: float, max_degrees: float) -> float:
	return clampf(accel * per_accel, -max_degrees, max_degrees)
