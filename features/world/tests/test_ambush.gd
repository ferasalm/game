extends TestCase
## Which side struck first: the patrol's walking direction, and last_touch_ambush() after a touch
## (0 nobody, 1 the patrol caught the player from behind, 2 the player caught the patrol from behind).

const DT: float = 1.0 / 60.0
const GAP: float = 0.3


func _make() -> Rooftop:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	tree.root.add_child(rooftop)
	return rooftop


## Puts the player GAP away from the patrol along its walking direction (+1 ahead of it, -1 behind it), facing
## along the walk (+1) or against it (-1), then lets the patrol touch him once.
func _touch(rooftop: Rooftop, side: float, player_facing: float) -> void:
	var walk: Vector3 = rooftop.patrol.facing()
	rooftop.player.position = rooftop.patrol.position + walk * GAP * side
	rooftop.player.facing = walk * player_facing
	rooftop.patrol._physics_process(DT)


func test_facing_is_flat_and_unit_length() -> void:
	var rooftop: Rooftop = _make()
	var walk: Vector3 = rooftop.patrol.facing()
	check(absf(walk.length() - 1.0) < 0.001, "unit length")
	check_eq(walk.y, 0.0, "flat on the floor")
	rooftop.free()


func test_zero_before_any_touch() -> void:
	var rooftop: Rooftop = _make()
	check_eq(rooftop.last_touch_ambush(), 0, "no touch yet")
	rooftop.free()


func test_patrol_catches_the_player_from_behind() -> void:
	var rooftop: Rooftop = _make()
	_touch(rooftop, 1.0, 1.0)
	check_eq(rooftop.last_touch_ambush(), 1, "the patrol walked into his back")
	rooftop.free()


func test_player_catches_the_patrol_from_behind() -> void:
	var rooftop: Rooftop = _make()
	_touch(rooftop, -1.0, 1.0)
	check_eq(rooftop.last_touch_ambush(), 2, "he came up behind the patrol")
	rooftop.free()


func test_face_to_face_is_nobody() -> void:
	var rooftop: Rooftop = _make()
	_touch(rooftop, 1.0, -1.0)
	check_eq(rooftop.last_touch_ambush(), 0, "they met head on")
	rooftop.free()
