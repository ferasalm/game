class_name ModelGait
extends RefCounted
## Pure choice of a model's looping clip: which gait (idle, walk, run) its measured ground speed and the state the
## facade asked for mean, and the playback rate that keeps its feet on the ground. No nodes here.


## &"idle", &"walk" or &"run". A body the game says is moving but that has not moved yet (blocked, or a test) walks or
## runs as asked; `asked` is the facade's state.
static func choose(def: ModelDef, speed: float, moving: bool, asked: StringName) -> StringName:
	var gait: StringName = Locomotion.gait(speed, def.idle_speed, def.run_speed, moving)
	if moving and gait == &"idle":
		return &"run" if asked == &"run" else &"walk"
	return gait


## The playback rate of a looping gait clip of `clip_seconds` at this speed (1 for idle, or when hardly moving).
static func rate(def: ModelDef, gait: StringName, speed: float, clip_seconds: float, lo: float, hi: float) -> float:
	if gait == &"idle" or speed <= def.idle_speed:
		return 1.0
	return Locomotion.playback_rate(speed, def.run_stride_m if gait == &"run" else def.stride_m, clip_seconds, lo, hi)
