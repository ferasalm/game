class_name TransitionDef
extends Def
## A screen transition between flow states: a plain fade or the qamariya-glass shatter, how long it runs and the
## colour it fades through (content/ui/transitions.json). The Router asks for them by id.

const KINDS: Array[StringName] = [&"fade", &"shatter"]

var kind: StringName = &"fade"
var seconds: float = 0.5
var color: Color = Color.BLACK


func read(r: DefReader) -> void:
	id = r.id()
	kind = r.one_of("kind", KINDS)
	seconds = r.number("seconds", 0.0, 10.0)
	color = r.color("color")
