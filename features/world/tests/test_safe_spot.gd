extends TestCase
## SafeSpot: a place counts after standing still, walking resets the clock, the newest spot is skipped when the player
## is wedged right there, and only the two newest spots are kept.

const A: Vector3 = Vector3(10.0, 0.0, 0.0)
const B: Vector3 = Vector3(20.0, 0.0, 0.0)
const C: Vector3 = Vector3(30.0, 0.0, 0.0)


func _rest(spot: SafeSpot, at: Vector3) -> void:
	spot.update(at, 0.0)  # arriving moves the anchor
	spot.update(at, 1.0)
	spot.update(at, 1.0)


func test_before_any_rest_the_fallback_is_used() -> void:
	var spot := SafeSpot.new(2.0, 1.5, Vector3.ZERO)
	check_eq(spot.last_safe(A), Vector3.ZERO, "the spawn")
	spot.update(A, 1.0)
	spot.update(A, 0.5)
	check(spot.spots().is_empty(), "walking about does not count")


func test_standing_still_long_enough_remembers_the_spot() -> void:
	var spot := SafeSpot.new(2.0, 1.5, Vector3.ZERO)
	_rest(spot, A)
	check_eq(spot.last_safe(B), A, "the rested spot")
	spot.update(A + Vector3(5.0, 0.0, 0.0), 1.0)
	spot.update(A + Vector3(5.0, 0.0, 0.0), 0.5)
	check_eq(spot.spots().size(), 1, "moving restarted the clock")


func test_wedged_at_the_newest_spot_goes_back_to_the_one_before() -> void:
	var spot := SafeSpot.new(2.0, 1.5, Vector3.ZERO)
	_rest(spot, A)
	_rest(spot, B)
	check_eq(spot.last_safe(C), B, "from elsewhere: the newest")
	check_eq(spot.last_safe(B), A, "wedged at the newest: the older one")
	check_eq(spot.last_safe(A + Vector3(0.5, 0.0, 0.0)), B, "near the older one: the newest")


func test_only_the_two_newest_spots_are_kept() -> void:
	var spot := SafeSpot.new(2.0, 1.5, Vector3.ZERO)
	_rest(spot, A)
	_rest(spot, B)
	_rest(spot, C)
	check_eq(spot.spots(), [B, C] as Array[Vector3], "A was forgotten")
	_rest(spot, C + Vector3(0.5, 0.0, 0.0))
	check_eq(spot.spots().size(), 2, "resting again nearby refreshes the newest instead of adding")
