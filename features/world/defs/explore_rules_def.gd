class_name ExploreRulesDef
extends Def
## Numbers for walking around an area: player speed and size, follower, camera, patrol, touch and interact
## ranges, collision wall height and the workshop prompt.

var walk_speed: float = 0.0
var follower_distance: float = 0.0
var follower_lag: float = 0.0
var follower_stop_distance: float = 0.0
var trail_step: float = 0.0
var camera_smoothing: float = 0.0
var patrol_speed: float = 0.0
var patrol_pause: float = 0.0
var patrol_respawn: float = 0.0
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
	camera_smoothing = r.number("camera_smoothing", 0.1, 100.0)
	patrol_speed = r.number("patrol_speed", 0.1, 20.0)
	patrol_pause = r.number("patrol_pause", 0.0, 30.0)
	patrol_respawn = r.number("patrol_respawn", 0.1, 120.0)
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
