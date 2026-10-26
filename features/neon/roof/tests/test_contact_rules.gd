class_name TestContactRules
extends TestCase
## purpose: verify ContactRules touching radius and ambush calculations.


func test_touching_within_and_outside_radius() -> void:
	var a := Vector2(100.0, 100.0)
	var b_close := Vector2(140.0, 100.0)
	var b_edge := Vector2(170.0, 100.0)
	var b_far := Vector2(171.0, 100.0)
	check(ContactRules.touching(a, b_close, 70.0), "40 px is within 70 px radius")
	check(ContactRules.touching(a, b_edge, 70.0), "70 px is exactly on boundary")
	check(not ContactRules.touching(a, b_far, 70.0), "71 px is outside radius")


func test_ambush_from_behind_is_true() -> void:
	var guard_pos := Vector2(200.0, 200.0)
	var facing := Vector2(1.0, 0.0)
	var hero_behind := Vector2(150.0, 200.0)
	check(ContactRules.is_ambush(guard_pos, facing, hero_behind), "hero behind guard is ambush")


func test_ambush_from_front_is_false() -> void:
	var guard_pos := Vector2(200.0, 200.0)
	var facing := Vector2(1.0, 0.0)
	var hero_front := Vector2(250.0, 200.0)
	check(not ContactRules.is_ambush(guard_pos, facing, hero_front), "hero in front of guard is not ambush")


func test_ambush_perpendicular() -> void:
	var guard_pos := Vector2(200.0, 200.0)
	var facing := Vector2(1.0, 0.0)
	var hero_side := Vector2(200.0, 250.0)
	check(not ContactRules.is_ambush(guard_pos, facing, hero_side), "perpendicular dot is not ambush")
