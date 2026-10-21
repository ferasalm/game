class_name SpeakerDef
extends Def
## One speaking character: name key, name colour, the pixel sprite id, and where
## the face sits on that sprite (sprite pixels). Stand-in portraits no longer use the sprite.

var name_key: String = ""
var color: Color = Color.WHITE
var sprite: StringName = &""
var face_x: int = 0
var brow_y: int = 0
var mouth_y: int = 0
## Mirror the real portrait so it faces the text box (art that faces away needs it; stand-ins already face it).
var portrait_flip: bool = false
## Localization key of the nameplate epithet under the name ("" = none).
var epithet_key: String = ""


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
	portrait_flip = r.flag("portrait_flip")
	epithet_key = r.text("epithet_key", "", false)


func references() -> Array[Array]:
	return [["sprite", sprite]]
