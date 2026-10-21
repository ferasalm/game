class_name ModelDef
extends Def
## Stub (v0.3 registry, filled by B4; docs/design/characters-3d.md): one live 3D character model: its glTF scene and
## height now; later the state -> animation map, clip timing, anchors (bone names), stride and turn speed.

var scene: String = ""
var height_m: float = 2.0


func read(r: DefReader) -> void:
	id = r.id()
	scene = r.text("scene", "", false)
	height_m = r.number("height_m", 0.1, 20.0, 2.0, false)
