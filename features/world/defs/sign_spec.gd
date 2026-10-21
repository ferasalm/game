class_name SignSpec
extends RefCounted
## One neon sign: a localization key (Arabic proper nouns and English together), a dark board with a glowing
## frame, the glow colour, a position and yaw, the text height in metres (size) and how much it flickers.

var key: String = ""
var pos: Vector3 = Vector3.ZERO
var yaw: float = 0.0
var size: float = 0.5
var board: Vector2 = Vector2(4.0, 1.0)
var color: Color = Color.WHITE
var energy: float = 2.5
var text_energy: float = 1.3
var flicker: float = 0.0


func read(r: DefReader) -> void:
	key = r.text("key")
	pos = Vector3(r.number("x", -500.0, 500.0), r.number("y", -50.0, 100.0), r.number("z", -500.0, 500.0))
	yaw = r.number("yaw", -360.0, 360.0, 0.0, false)
	size = r.number("size", 0.1, 5.0, 0.5, false)
	var b: Array[float] = r.float_list("board", 0.2, 30.0)
	if b.size() == 2:
		board = Vector2(b[0], b[1])
	color = r.color("color")
	energy = r.number("energy", 0.5, 16.0, 2.5, false)
	text_energy = r.number("text_energy", 0.2, 16.0, 1.3, false)
	flicker = r.number("flicker", 0.0, 1.0, 0.0, false)
