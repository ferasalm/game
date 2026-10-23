class_name DialogueLine
extends RefCounted
## One spoken line: who says it, with which expression, localization key, and optional choices.

const EXPRESSIONS: Array[StringName] = [&"neutral", &"happy", &"angry", &"surprised"]

var speaker: StringName = &""
var expression: StringName = &"neutral"
var text_key: String = ""
var choices: Array[DialogueChoice] = []


func read(r: DefReader) -> void:
	speaker = r.id("speaker")
	expression = r.one_of("expression", EXPRESSIONS)
	text_key = r.text("text")
	choices.clear()
	for cr: DefReader in r.optional_objects("choices"):
		var choice := DialogueChoice.new()
		choice.read(cr)
		choices.append(choice)
