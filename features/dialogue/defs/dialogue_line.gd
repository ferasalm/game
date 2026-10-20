class_name DialogueLine
extends RefCounted
## One spoken line: who says it, with which expression, and the localization key of the text.

const EXPRESSIONS: Array[StringName] = [&"neutral", &"happy", &"angry", &"surprised"]

var speaker: StringName = &""
var expression: StringName = &"neutral"
var text_key: String = ""


func read(r: DefReader) -> void:
	speaker = r.id("speaker")
	expression = r.one_of("expression", EXPRESSIONS)
	text_key = r.text("text")
