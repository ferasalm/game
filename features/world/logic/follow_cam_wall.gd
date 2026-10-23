class_name FollowCamWall
extends RefCounted
## Wall-rise helpers for FollowCam.

static func rise_candidates(base_pitch: float, max_pitch: float, step: float) -> Array[float]:
	var out: Array[float] = []
	var p: float = base_pitch
	while p < max_pitch - 0.001:
		out.append(p)
		p += step
	out.append(max_pitch)
	return out


static func ease_wall_rise(current: float, target: float, delta: float, up_rate: float, down_rate: float) -> float:
	if target > current:
		return current + (target - current) * (1.0 - exp(-up_rate * delta))
	else:
		return current + (target - current) * (1.0 - exp(-down_rate * delta))
