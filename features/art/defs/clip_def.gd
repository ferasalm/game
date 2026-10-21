class_name ClipDef
extends Def
## Stub (v0.3 registry, filled by B4): the timing of one model clip (attack, cast, hurt...): its length in seconds
## and whether it loops; B4 adds the wind-up / hold / strike retiming and impact_t.

var seconds: float = 1.0
var loops: bool = false


func read(r: DefReader) -> void:
	id = r.id()
	seconds = r.number("seconds", 0.05, 30.0, 1.0, false)
	loops = r.flag("loops")
