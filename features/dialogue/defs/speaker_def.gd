class_name SpeakerDef
extends Def
## One speaking character: name key, name colour, the pixel sprite used for the stand-in portrait, and where
## the face sits on that sprite (sprite pixels) so the stand-in can draw brows and a mouth.

var name_key: String = ""
var color: Color = Color.WHITE
var sprite: StringName = &""
var face_x: int = 0
var brow_y: int = 0
var mouth_y: int = 0


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	var hex: String = r.text("color")
	if Color.html_is_valid(hex):
		color = Color.html(hex)
	else:
		push_error("speaker '%s': '%s' is not a colour" % [id, hex])
	sprite = r.id("sprite")
	face_x = r.integer("face_x", 0, 63)
	brow_y = r.integer("brow_y", 0, 63)
	mouth_y = r.integer("mouth_y", 0, 63)


func references() -> Array[Array]:
	return [["sprite", sprite]]
