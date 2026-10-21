class_name LightPick
extends RefCounted
## Which practical lights get a real OmniLight: the nearest few to a focus point (the rest keep only their fake
## light pool), plus the fade and flicker maths. Pure.


## Indices into positions of the count nearest entries that are allowed (real[i]), nearest first.
static func nearest(positions: Array[Vector3], real: Array[bool], focus: Vector3, count: int) -> Array[int]:
	var order: Array[int] = []
	for i: int in positions.size():
		if real[i]:
			order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return positions[a].distance_squared_to(focus) < positions[b].distance_squared_to(focus))
	return order.slice(0, count)


## Moves value towards 1 (wanted) or 0 by speed per second.
static func fade(value: float, wanted: bool, delta: float, speed: float) -> float:
	return clampf(value + (1.0 if wanted else -1.0) * speed * delta, 0.0, 1.0)


## A multiplier in (1 - amount)..1 that wobbles irregularly with time (two sines at unrelated speeds).
static func flicker(amount: float, speed: float, phase: float, time: float) -> float:
	if amount <= 0.0:
		return 1.0
	var wobble: float = 0.5 + 0.25 * sin(time * speed + phase) + 0.25 * sin(time * speed * 2.37 + phase * 1.7)
	return 1.0 - amount * (1.0 - wobble)


## Stable phase 0..2pi for a light at pos (so two lanterns do not flicker together).
static func phase_of(pos: Vector3) -> float:
	return fmod(absf(sin(pos.x * 12.9898 + pos.z * 78.233)) * 43758.5453, 1.0) * TAU
