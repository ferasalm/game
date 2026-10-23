extends TestCase
## The pure maths behind live 3D characters: ClipTiming (wind-up, hold, strike, recovery and the events on that
## curve), Locomotion (gait, stride to playback rate, lean, foot contacts passed) and YawTurn (the capped short-way turn).


func _clip() -> ClipDef:
	var clip := ClipDef.new()
	clip.seconds = 1.5
	clip.windup_t = 0.35
	clip.impact_t = 0.6
	clip.strike_end_t = 0.7
	clip.windup_rate = 0.7
	clip.hold = 0.08
	clip.strike_rate = 1.8
	clip.recover_rate = 1.0
	return clip


func test_segments_cover_the_whole_clip() -> void:
	var clip: ClipDef = _clip()
	var covered: float = 0.0
	for segment: Vector3 in ClipTiming.segments(clip):
		covered += segment.y - segment.x
	check(is_equal_approx(covered, clip.seconds), "the segments span the clip's length")
	var expected: float = 0.35 / 0.7 + 0.08 + 0.35 / 1.8 + 0.8
	check(is_equal_approx(ClipTiming.total(clip), expected), "real length = wind-up + hold + strike + recovery")


func test_plain_clip_runs_at_its_own_speed() -> void:
	var clip := ClipDef.new()
	clip.seconds = 0.4
	check(is_equal_approx(ClipTiming.total(clip), 0.4), "no retiming: real length = clip length")
	check(is_equal_approx(ClipTiming.clip_at(clip, 0.1), 0.1), "and the pose follows real time")


func test_hold_freezes_the_pose() -> void:
	var clip: ClipDef = _clip()
	var start: float = 0.35 / 0.7
	check(is_equal_approx(ClipTiming.clip_at(clip, start), 0.35), "the wind-up ends at windup_t")
	check(is_equal_approx(ClipTiming.clip_at(clip, start + 0.04), 0.35), "the pose holds during the hold")
	check(ClipTiming.clip_at(clip, start + 0.1) > 0.35, "then the strike moves on")


func test_slices_add_up_to_clip_time() -> void:
	var clip: ClipDef = _clip()
	var moved: float = 0.0
	for piece: Vector2 in ClipTiming.slices(clip, 0.2, 0.9):
		moved += piece.x * piece.y
	check(is_equal_approx(moved, ClipTiming.clip_at(clip, 0.9) - ClipTiming.clip_at(clip, 0.2)), "rate x time = clip time")
	check(ClipTiming.slices(clip, 0.2, 0.2).is_empty(), "no time, no slices")
	var rates: Array[float] = []
	for piece: Vector2 in ClipTiming.slices(clip, 0.0, ClipTiming.total(clip)):
		rates.append(piece.x)
	check(rates.size() == 4 and is_equal_approx(rates[0], 0.7), "the wind-up runs at 0.7x")
	check(is_equal_approx(rates[1], 0.0) and is_equal_approx(rates[2], 1.8), "the hold stands still, the strike runs at 1.8x")


func test_events_fire_once_on_the_curve() -> void:
	var clip: ClipDef = _clip()
	var hit: float = ClipTiming.real_at(clip, clip.impact_t)
	check(ClipTiming.real_at(clip, 0.35) < hit, "the impact comes after the wind-up")
	check_eq(ClipTiming.events(clip, hit - 0.01, hit + 0.01), [&"impact"] as Array[StringName], "impact at its time")
	check(ClipTiming.events(clip, hit, hit + 0.5).is_empty(), "and not again (the start is exclusive)")
	var end: float = ClipTiming.total(clip)
	check_eq(ClipTiming.events(clip, end - 0.01, end + 1.0), [&"end"] as Array[StringName], "end at the total")
	var both: Array[StringName] = ClipTiming.events(clip, -0.001, end)
	check_eq(both, [&"impact", &"end"] as Array[StringName], "one long step still gives both, in order")
	clip.impact_t = -1.0
	check_eq(ClipTiming.events(clip, -0.001, end), [&"end"] as Array[StringName], "a clip without impact only ends")


func test_gait_and_stride() -> void:
	check_eq(Locomotion.gait(0.0, 0.1, 2.6), &"idle", "still is idle")
	check_eq(Locomotion.gait(1.6, 0.1, 2.6), &"walk", "a patrol speed walks")
	check_eq(Locomotion.gait(3.5, 0.1, 2.6), &"run", "the player's speed runs")
	check_eq(Locomotion.gait(0.06, 0.1, 2.6, true), &"walk", "a moving body keeps its gait a little longer")
	var rate: float = Locomotion.playback_rate(1.8, 1.8, 1.0, 0.5, 2.0)
	check(is_equal_approx(rate, 1.0), "a cycle of 1.8 m at 1.8 m/s plays at 1x")
	check(is_equal_approx(Locomotion.playback_rate(3.6, 1.8, 1.0, 0.5, 2.0), 2.0), "twice the speed, twice the rate")
	check(is_equal_approx(Locomotion.playback_rate(30.0, 1.8, 1.0, 0.5, 2.0), 2.0), "capped at hi")
	check(is_equal_approx(Locomotion.playback_rate(1.0, 0.0, 1.0, 0.5, 2.0), 1.0), "no stride: 1x")


func test_feet_do_not_slide() -> void:
	# Distance walked in a second (speed) = cycles played x stride.
	var stride: float = 2.0
	var seconds: float = 1.2
	for speed: float in [1.0, 1.7, 2.4]:
		var cycles: float = Locomotion.playback_rate(speed, stride, seconds, 0.1, 5.0) / seconds
		check(is_equal_approx(cycles * stride, speed), "stride x cycles per second = speed at %s m/s" % speed)


func test_smooth_and_lean() -> void:
	check(is_equal_approx(Locomotion.smooth(0.0, 1.0, 100.0, 10.0), 1.0), "smoothing arrives")
	check(Locomotion.smooth(0.0, 1.0, 0.016, 10.0) < 0.2, "slowly at first")
	check_eq(Locomotion.lean(100.0, 0.5, 7.0), 7.0, "lean is capped")
	check_eq(Locomotion.lean(-100.0, 0.5, 7.0), -7.0, "both ways")


func test_yaw_turn() -> void:
	check(is_equal_approx(YawTurn.yaw_of(Vector3(1.0, 0.0, 0.0), 0.0), PI / 2.0), "+x is a quarter turn")
	check(is_equal_approx(YawTurn.yaw_of(Vector3(0.0, 0.0, 1.0), 1.0), 0.0), "+z (the camera) is yaw 0")
	check_eq(YawTurn.yaw_of(Vector3.ZERO, 1.25), 1.25, "no direction keeps the yaw")
	check(is_equal_approx(YawTurn.step(0.0, 1.0, 2.0, 0.1), 0.2), "a step is capped by rate x time")
	check(is_equal_approx(YawTurn.step(0.0, 0.1, 2.0, 0.1), 0.1), "and lands on the target")
	var around: float = YawTurn.step(PI - 0.1, -PI + 0.1, 1.0, 0.05)
	check(around > PI - 0.1, "from 170 to -170 degrees turns the short way (past 180)")
	check(YawTurn.arrived(PI, -PI), "the same angle either side of the seam")
	var turned: float = 0.0
	for i: int in 60:
		turned = YawTurn.step(turned, PI, deg_to_rad(900.0), 1.0 / 60.0)
	check(YawTurn.arrived(turned, PI), "900 deg/s turns about backwards in a quarter second")


func test_foot_contacts_passed_wrap_with_the_loop() -> void:
	var contacts: Array[float] = [0.0, 0.667]
	check_eq(Locomotion.contacts_passed(contacts, 1.333, 0.0, 0.6), 0, "the contact at the start was already counted")
	check_eq(Locomotion.contacts_passed(contacts, 1.333, 0.6, 0.7), 1, "the second heel strike")
	check_eq(Locomotion.contacts_passed(contacts, 1.333, 1.3, 1.4), 1, "the first heel strike again after the wrap")
	check_eq(Locomotion.contacts_passed(contacts, 1.333, 0.1, 4.1), 6, "three laps, two steps each")
	check_eq(Locomotion.contacts_passed(contacts, 1.333, 0.5, 0.5), 0, "no time, no step")
	check_eq(Locomotion.contacts_passed([] as Array[float], 1.333, 0.0, 9.0), 0, "a clip without contacts is silent")
