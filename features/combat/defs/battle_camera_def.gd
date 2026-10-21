class_name BattleCameraDef
extends Def
## The cinematic battle camera (content/combat/camera.json): the low pose it swoops to from the exploration
## camera, the gentle idle drift, how far it follows the acting side, the push-in on big moves and the victory pose.
## Positions are metres from the battle anchor.

var swoop_time: float = 1.0
var pos: Vector3 = Vector3.ZERO
var look: Vector3 = Vector3.ZERO
var fov: float = 34.0
var dof_scale: float = 0.5
var drift: Vector2 = Vector2.ZERO
var drift_speed: float = 0.4
## Share of the acting unit's x offset that the camera and its look target follow, and how fast it eases.
var follow: float = 0.2
var follow_speed: float = 4.0
## FOV degrees removed at zoom 1.0 and how fast the push eases back.
var push_fov: float = 30.0
var push_speed: float = 6.0
var victory_pos: Vector3 = Vector3.ZERO
var victory_look: Vector3 = Vector3.ZERO
var victory_fov: float = 30.0
var victory_time: float = 1.2


func read(r: DefReader) -> void:
	id = r.id()
	swoop_time = r.number("swoop_time", 0.0, 6.0)
	pos = _v3(r, "pos")
	look = _v3(r, "look")
	fov = r.number("fov", 5.0, 120.0)
	dof_scale = r.number("dof_scale", 0.0, 3.0)
	drift = Vector2(r.number("drift_x", 0.0, 3.0), r.number("drift_y", 0.0, 3.0))
	drift_speed = r.number("drift_speed", 0.0, 5.0)
	follow = r.number("follow", 0.0, 1.0)
	follow_speed = r.number("follow_speed", 0.1, 30.0)
	push_fov = r.number("push_fov", 0.0, 100.0)
	push_speed = r.number("push_speed", 0.1, 30.0)
	victory_pos = _v3(r, "victory_pos")
	victory_look = _v3(r, "victory_look")
	victory_fov = r.number("victory_fov", 5.0, 120.0)
	victory_time = r.number("victory_time", 0.0, 6.0)


func _v3(r: DefReader, key: String) -> Vector3:
	return Vector3(r.number(key + "_x", -50.0, 50.0), r.number(key + "_y", -50.0, 50.0),
		r.number(key + "_z", -50.0, 50.0))
