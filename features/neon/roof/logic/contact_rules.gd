class_name ContactRules
extends RefCounted
## purpose: pure distance and ambush detection rules for iso exploration contact.


## True when pos_a and pos_b are within radius pixels of each other.
static func touching(pos_a: Vector2, pos_b: Vector2, radius: float) -> bool:
	return pos_a.distance_to(pos_b) <= radius


## True when the guard faces away from the hero (dot product of guard's facing vector and to-hero vector < 0).
static func is_ambush(guard_pos: Vector2, facing_vector: Vector2, hero_pos: Vector2) -> bool:
	var to_hero: Vector2 = hero_pos - guard_pos
	return facing_vector.dot(to_hero) < 0.0
