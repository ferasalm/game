class_name ExploreRulesDef
extends Def
## Numbers for walking around an area: player speed and size, follower, camera, patrol, touch and interact
## ranges, collision wall height and the workshop prompt.

var walk_speed: float = 0.0
var follower_distance: float = 0.0
var follower_lag: float = 0.0
var follower_stop_distance: float = 0.0
var trail_step: float = 0.0
## Bilqis snaps back onto the trail when wedged this long (seconds, moved/wanted below the ratio) or past the leash (m).
var follower_stuck_seconds: float = 0.6
var follower_stuck_ratio: float = 0.2
var follower_leash: float = 4.0
var camera_smoothing: float = 0.0
var patrol_speed: float = 0.0
var patrol_pause: float = 0.0
## After a battle or a sabil drink no patrol can touch for this long; the party stands at least safe_return_distance
## from every patrol, and unstuck picks a spot at least unstuck_patrol_distance away (all metres).
var touch_grace: float = 3.0
var safe_return_distance: float = 3.5
var unstuck_patrol_distance: float = 3.0
## How many standing-still spots are remembered for unstuck.
var safe_ring: int = 8
## The workshop bench mesh (a box): size in metres and colour.
var bench_size: Vector3 = Vector3(1.6, 0.9, 0.7)
var bench_color: Color = Color.SADDLE_BROWN
var touch_radius: float = 0.0
var interact_radius: float = 0.0
var capsule_radius: float = 0.3
var capsule_height: float = 1.6
var wall_height: float = 3.0
var prompt_height: float = 0.0
var prompt_pixel_size: float = 0.01
var prompt_font_size: int = 48
## Chest lid: how far it swings (degrees) and how long it takes (seconds).
var chest_open_angle: float = 100.0
var chest_open_time: float = 0.6


func read(r: DefReader) -> void:
	id = r.id()
	walk_speed = r.number("walk_speed", 0.1, 20.0)
	follower_distance = r.number("follower_distance", 0.1, 10.0)
	follower_lag = r.number("follower_lag", 0.1, 100.0)
	follower_stop_distance = r.number("follower_stop_distance", 0.0, 2.0)
	trail_step = r.number("trail_step", 0.01, 2.0)
	follower_stuck_seconds = r.number("follower_stuck_seconds", 0.1, 10.0)
	follower_stuck_ratio = r.number("follower_stuck_ratio", 0.0, 1.0)
	follower_leash = r.number("follower_leash", 0.5, 30.0)
	camera_smoothing = r.number("camera_smoothing", 0.1, 100.0)
	patrol_speed = r.number("patrol_speed", 0.1, 20.0)
	patrol_pause = r.number("patrol_pause", 0.0, 30.0)
	touch_grace = r.number("touch_grace", 0.0, 30.0)
	safe_return_distance = r.number("safe_return_distance", 0.0, 30.0)
	unstuck_patrol_distance = r.number("unstuck_patrol_distance", 0.0, 30.0)
	safe_ring = r.integer("safe_ring", 1, 64)
	var bench: Array[float] = r.float_list("bench_size", 0.1, 10.0)
	if bench.size() == 3:
		bench_size = Vector3(bench[0], bench[1], bench[2])
	bench_color = r.color("bench_color", bench_color, false)
	touch_radius = r.number("touch_radius", 0.1, 5.0)
	interact_radius = r.number("interact_radius", 0.1, 5.0)
	capsule_radius = r.number("capsule_radius", 0.05, 2.0)
	capsule_height = r.number("capsule_height", 0.2, 4.0)
	wall_height = r.number("wall_height", 0.5, 20.0)
	prompt_height = r.number("prompt_height", 0.0, 3.0)
	prompt_pixel_size = r.number("prompt_pixel_size", 0.001, 0.1)
	prompt_font_size = r.integer("prompt_font_size", 8, 200)
	chest_open_angle = r.number("chest_open_angle", 10.0, 170.0, chest_open_angle, false)
	chest_open_time = r.number("chest_open_time", 0.05, 5.0, chest_open_time, false)
