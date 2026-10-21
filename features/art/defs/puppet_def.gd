class_name PuppetDef
extends Def
## Stub (v0.3 registry, filled by the puppet builder): one painted puppet, cut into parts from a full-body
## picture and animated in code. For now only an id, its source picture and its height in metres.

var source: String = ""
var height_m: float = 1.8


func read(r: DefReader) -> void:
	id = r.id()
	source = r.text("source", "", false)
	height_m = r.number("height_m", 0.1, 20.0, 1.8, false)
