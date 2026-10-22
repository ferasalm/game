class_name ClipTiming
extends RefCounted
## Pure retiming of a one-shot clip (ClipDef): real seconds <-> clip seconds. A clip is cut into segments (clip_from,
## clip_to, real seconds): wind-up at windup_rate, a hold at the wind-up's end, the strike at strike_rate, then
## recovery at recover_rate. The model source advances its manual AnimationPlayer slice by slice, so a pose never
## drifts off these curves; events (&"impact", &"end") are read off the same curve. No nodes here.


## The segments of the clip in order: x = clip seconds at the start, y = at the end, z = real seconds it takes.
static func segments(c: ClipDef) -> Array[Vector3]:
	var out: Array[Vector3] = []
	_add(out, 0.0, c.windup_t, c.windup_rate)
	if c.windup_t > 0.0 and c.hold > 0.0:
		out.append(Vector3(c.windup_t, c.windup_t, c.hold))
	_add(out, c.windup_t, c.strike_end_t, c.strike_rate)
	_add(out, maxf(c.strike_end_t, c.windup_t), c.seconds, c.recover_rate)
	return out


## Real seconds the whole clip takes.
static func total(c: ClipDef) -> float:
	var sum: float = 0.0
	for segment: Vector3 in segments(c):
		sum += segment.z
	return sum


## Real seconds after the start when clip time `t` is reached (the first time it is).
static func real_at(c: ClipDef, t: float) -> float:
	var elapsed: float = 0.0
	for segment: Vector3 in segments(c):
		if t <= segment.y and segment.y > segment.x:
			return elapsed + (t - segment.x) / (segment.y - segment.x) * segment.z
		elapsed += segment.z
	return elapsed


## Where in the clip (seconds) the pose is after `real` seconds.
static func clip_at(c: ClipDef, real: float) -> float:
	var left: float = real
	for segment: Vector3 in segments(c):
		if left <= segment.z:
			return lerpf(segment.x, segment.y, left / segment.z) if segment.z > 0.0 else segment.y
		left -= segment.z
	return c.seconds


## The pieces of the span real `from`..`to`: x = playback rate, y = real seconds, in order. Their sum of x * y is
## exactly the clip time travelled; a hold is a piece of rate 0.
static func slices(c: ClipDef, from: float, to: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var at: float = 0.0
	for segment: Vector3 in segments(c):
		var start: float = maxf(from, at)
		var stop: float = minf(to, at + segment.z)
		if stop > start:
			out.append(Vector2((segment.y - segment.x) / segment.z, stop - start))
		at += segment.z
	return out


## The events passed while real time goes from `from` (exclusive) to `to` (inclusive): &"impact" then &"end".
static func events(c: ClipDef, from: float, to: float) -> Array[StringName]:
	var out: Array[StringName] = []
	if c.impact_t >= 0.0:
		var hit: float = real_at(c, c.impact_t)
		if from < hit and hit <= to:
			out.append(&"impact")
	if from < total(c) and total(c) <= to:
		out.append(&"end")
	return out


static func _add(out: Array[Vector3], from: float, to: float, rate: float) -> void:
	if to > from:
		out.append(Vector3(from, to, (to - from) / rate))
