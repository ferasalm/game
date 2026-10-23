class_name BackdropDef
extends Def
## Backdrop definition for full-screen menu backgrounds.

var path: String = ""
var dim: float = 0.35


func read(r: DefReader) -> void:
	id = r.id()
	path = r.text("path")
	dim = r.number("dim", 0.0, 1.0, 0.35, false)
