class_name DialogueChoice
extends RefCounted
## A player choice at the end of a dialogue line: text key, next dialogue (or "end"), and effects.

var text_key: String = ""
var next: StringName = &"end"
var effects: PackedStringArray = PackedStringArray()


func read(r: DefReader) -> void:
	text_key = r.text("text")
	next = StringName(r.text("next", "end", false))
	effects = r.text_list("effects") if r.has("effects") else PackedStringArray()
