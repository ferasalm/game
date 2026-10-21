class_name ClipDef
extends Def
## Stub (v0.3 registry, filled by the puppet builder): one keyframed puppet clip (attack, cast, hurt...) with its
## length in seconds and whether it loops.

var seconds: float = 1.0
var loops: bool = false


func read(r: DefReader) -> void:
	id = r.id()
	seconds = r.number("seconds", 0.05, 30.0, 1.0, false)
	loops = r.flag("loops")
