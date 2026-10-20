class_name LookDef
extends Def
## The HD-2D look as data: camera offset and field of view, tilt-shift depth of field, sun, ambient light,
## background and bloom. Look v1 is the accepted look-test picture (docs/DECISIONS).

var camera_offset: Vector3 = Vector3(0.0, 6.0, 8.5)
var look_height: float = 0.8
var fov: float = 30.0
var dof_near: float = 5.0
var dof_far: float = 12.0
var dof_amount: float = 0.1
var sun_rotation: Vector3 = Vector3(-50.0, -35.0, 0.0)
var sun_color: Color = Color.WHITE
var ambient_color: Color = Color.WHITE
var ambient_energy: float = 0.5
var background_color: Color = Color.BLACK
var glow_bloom: float = 0.0


func read(r: DefReader) -> void:
	id = r.id()
	camera_offset = Vector3(r.number("camera_offset_x", -50.0, 50.0), r.number("camera_offset_y", 0.0, 50.0),
		r.number("camera_offset_z", -50.0, 50.0))
	look_height = r.number("look_height", 0.0, 5.0)
	fov = r.number("fov", 5.0, 120.0)
	dof_near = r.number("dof_near", 0.0, 100.0)
	dof_far = r.number("dof_far", 0.0, 200.0)
	dof_amount = r.number("dof_amount", 0.0, 1.0)
	sun_rotation = Vector3(r.number("sun_pitch", -90.0, 90.0), r.number("sun_yaw", -180.0, 180.0), 0.0)
	sun_color = _color(r, "sun_color")
	ambient_color = _color(r, "ambient_color")
	ambient_energy = r.number("ambient_energy", 0.0, 4.0)
	background_color = _color(r, "background_color")
	glow_bloom = r.number("glow_bloom", 0.0, 1.0)


func _color(r: DefReader, key: String) -> Color:
	var value: String = r.text(key)
	if not Color.html_is_valid(value):
		push_error("look '%s': %s '%s' is not a colour" % [id, key, value])
		return Color.MAGENTA
	return Color.html(value)
