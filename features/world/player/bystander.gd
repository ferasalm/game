class_name Bystander
extends Node3D
## A person who stands where the level puts him (the herb seller): an idle picture turned the way the place says.
## He is no interact spot; the stall next to him is. A magenta placeholder shows until his picture or model exists.

var _visual: CharacterVisual


## sprite: the picture or model id; yaw_deg: the way he faces (0 = toward +z, the camera).
func _init(sprite: StringName, yaw_deg: float) -> void:
	_visual = CharacterVisual.new()
	_visual.set_sprite(sprite)
	add_child(_visual)
	_visual.face_dir(Vector3(sin(deg_to_rad(yaw_deg)), 0.0, cos(deg_to_rad(yaw_deg))))


func visual() -> CharacterVisual:
	return _visual
