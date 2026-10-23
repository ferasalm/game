class_name PuzzleYardDef
extends Def
## purpose: Defines the grey-box puzzle yard: floor, walls, ledge, tower, camera, colours and view sizes.

var place_yaw: float = 0.0
var floor_size: Vector2 = Vector2(14.0, 10.0)
var floor_color: Color = Color.MAGENTA
var back_wall_z: float = -5.0
var back_wall_height: float = 6.0
var back_wall_thickness: float = 0.2
var back_wall_color: Color = Color.MAGENTA
var parapet_height: float = 0.6
var parapet_thickness: float = 0.2
var parapet_color: Color = Color.MAGENTA
var ledge_x_min: float = -10.0
var ledge_x_max: float = -7.5
var ledge_z_min: float = 1.0
var ledge_z_max: float = 5.0
var ledge_top: float = 0.4
var ledge_color: Color = Color.MAGENTA
var tower_size: Vector3 = Vector3(2.0, 8.0, 2.0)
var tower_at: Vector3 = Vector3(-13.0, 4.0, 2.0)
var tower_color: Color = Color.MAGENTA
var camera_at: Vector3 = Vector3(0.0, 7.0, 11.0)
var camera_look_at: Vector3 = Vector3(0.0, 0.5, -1.0)
var camera_fov: float = 50.0
var interact_range: float = 1.3
var walk_speed: float = 3.0
var player_radius: float = 0.2
var player_height: float = 1.7
var player_color: Color = Color.MAGENTA
var marker_radius: float = 0.1
var marker_height: float = 0.6
var marker_color: Color = Color.MAGENTA
var beam_width: float = 0.08
var beam_alpha: float = 0.7
var beam_open_length: float = 4.0
var window_size: Vector2 = Vector2(1.0, 1.4)
var mirror_size: Vector3 = Vector3(0.15, 1.0, 0.8)
var mirror_post: float = 0.08
var lens_radius: float = 0.35
var flicker_hz: float = 9.0
var flicker_min: float = 0.6
var flicker_max: float = 1.4
var seal_radius: float = 0.5
var seal_turn_secs: float = 0.8
var channel_width: float = 0.4
var channel_depth: float = 0.15
var channel_color: Color = Color.MAGENTA
var water_alpha_base: float = 0.4
var water_alpha_share: float = 0.5
var water_scroll_speed: float = 0.3
var strip_height: float = 0.02
var gate_size: Vector3 = Vector3(0.5, 0.6, 0.1)
var gate_open_raise: float = 0.5
var gate_jam_tilt: float = 10.0
var spout_length: float = 0.8
var spout_width: float = 0.15
var grate_size: Vector2 = Vector2(1.2, 0.6)
var grate_height: float = 0.05
var dock_size: Vector2 = Vector2(1.6, 1.2)
var dock_height: float = 0.05
var drone_size: float = 0.4
var drone_sag: float = 0.15
var gauge_height: float = 1.0
var hint_show_secs: float = 5.0
var colors: Dictionary[StringName, Color] = {}


func read(r: DefReader) -> void:
	id = r.id()
	place_yaw = r.number("place_yaw", -360.0, 360.0, 0.0, false)
	_read_build(r)
	_read_camera(r)
	_read_pieces(r)
	_read_water(r)
	_read_colors(r)


func color(key: StringName) -> Color:
	return colors.get(key, Color.MAGENTA)


func _read_build(r: DefReader) -> void:
	var floor_r: DefReader = r.child("floor")
	floor_size = PuzzleDefCoords.vec2(floor_r, "size")
	floor_color = floor_r.color("color")
	var wall: DefReader = r.child("back_wall")
	back_wall_z = wall.number("z", -100.0, 100.0)
	back_wall_height = wall.number("height", 0.1, 100.0)
	back_wall_thickness = wall.number("thickness", 0.01, 10.0)
	back_wall_color = wall.color("color")
	var par: DefReader = r.child("parapet")
	parapet_height = par.number("height", 0.01, 10.0)
	parapet_thickness = par.number("thickness", 0.01, 10.0)
	parapet_color = par.color("color")
	var ledge: DefReader = r.child("ledge")
	var lx: Array[float] = ledge.float_list("x", -100.0, 100.0)
	var lz: Array[float] = ledge.float_list("z", -100.0, 100.0)
	if lx.size() == 2 and lz.size() == 2:
		ledge_x_min = lx[0]
		ledge_x_max = lx[1]
		ledge_z_min = lz[0]
		ledge_z_max = lz[1]
	else:
		ledge.problem("x", "ledge needs x and z ranges")
	ledge_top = ledge.number("top", 0.0, 10.0)
	ledge_color = ledge.color("color")
	var tower: DefReader = r.child("tower")
	tower_size = PuzzleDefCoords.vec3(tower, "size")
	tower_at = PuzzleDefCoords.vec3(tower, "at")
	tower_color = tower.color("color")


func _read_camera(r: DefReader) -> void:
	var cam: DefReader = r.child("camera")
	camera_at = PuzzleDefCoords.vec3(cam, "at")
	camera_look_at = PuzzleDefCoords.vec3(cam, "look_at")
	camera_fov = cam.number("fov", 1.0, 179.0)
	interact_range = r.number("interact_range", 0.1, 20.0)
	walk_speed = r.number("walk_speed", 0.1, 20.0)
	var p: DefReader = r.child("player")
	player_radius = p.number("radius", 0.05, 2.0)
	player_height = p.number("height", 0.1, 5.0)
	player_color = p.color("color")
	var m: DefReader = r.child("marker")
	marker_radius = m.number("radius", 0.01, 2.0)
	marker_height = m.number("height", 0.0, 10.0)
	marker_color = m.color("color")


func _read_pieces(r: DefReader) -> void:
	var beam: DefReader = r.child("beam")
	beam_width = beam.number("width", 0.01, 1.0)
	beam_alpha = beam.number("alpha", 0.0, 1.0)
	beam_open_length = beam.number("open_length", 0.1, 50.0)
	var win: DefReader = r.child("window")
	window_size = Vector2(win.number("width", 0.1, 10.0), win.number("height", 0.1, 10.0))
	var mir: DefReader = r.child("mirror")
	mirror_size = PuzzleDefCoords.vec3(mir, "size")
	mirror_post = mir.number("post", 0.01, 2.0)
	var lens: DefReader = r.child("lens")
	lens_radius = lens.number("radius", 0.01, 5.0)
	flicker_hz = lens.number("flicker_hz", 0.0, 100.0)
	flicker_min = lens.number("flicker_min", 0.0, 20.0)
	flicker_max = lens.number("flicker_max", 0.0, 20.0)
	var seal: DefReader = r.child("seal")
	seal_radius = seal.number("radius", 0.01, 5.0)
	seal_turn_secs = seal.number("turn_secs", 0.01, 10.0)
	var hint: DefReader = r.child("hints")
	hint_show_secs = hint.number("show_secs", 0.1, 60.0)


func _read_water(r: DefReader) -> void:
	var ch: DefReader = r.child("channel")
	channel_width = ch.number("width", 0.01, 5.0)
	channel_depth = ch.number("depth", 0.01, 5.0)
	channel_color = ch.color("color")
	var w: DefReader = r.child("water")
	water_alpha_base = w.number("alpha_base", 0.0, 1.0)
	water_alpha_share = w.number("alpha_share", 0.0, 1.0)
	water_scroll_speed = w.number("scroll_speed", 0.0, 20.0)
	strip_height = w.number("strip_height", 0.001, 1.0)
	var gate: DefReader = r.child("gate")
	gate_size = PuzzleDefCoords.vec3(gate, "size")
	gate_open_raise = gate.number("open_raise", 0.0, 5.0)
	gate_jam_tilt = gate.number("jam_tilt", 0.0, 90.0)
	var spout: DefReader = r.child("spout")
	spout_length = spout.number("length", 0.01, 10.0)
	spout_width = spout.number("width", 0.01, 5.0)
	var gr: DefReader = r.child("grate")
	grate_size = PuzzleDefCoords.vec2(gr, "size")
	grate_height = gr.number("height", 0.001, 2.0)
	var dock: DefReader = r.child("dock")
	dock_size = PuzzleDefCoords.vec2(dock, "size")
	dock_height = dock.number("height", 0.001, 2.0)
	drone_size = dock.number("drone", 0.01, 5.0)
	drone_sag = dock.number("drone_sag", 0.0, 2.0)
	var canyon: DefReader = r.child("canyon")
	gauge_height = canyon.number("gauge_height", 0.01, 10.0)


func _read_colors(r: DefReader) -> void:
	colors.clear()
	var raw: Dictionary[String, String] = r.text_map("colors")
	for key: String in raw:
		var value: String = raw[key]
		if Color.html_is_valid(value):
			colors[StringName(key)] = Color.html(value)
		else:
			r.problem("colors", "'%s' is not a colour" % value)
