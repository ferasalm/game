class_name BattleRects
extends RefCounted
## Where each fighter stands on the screen: the box of a CharacterVisual (its width and height from the facade) is
## projected with the battle camera and boxed again, so panels, strips and the mouse can steer clear of the fighters
## whatever the art is (sprite, model). Positions are in viewport pixels (1920x1080 layout space).

## How deep the box is, as a share of the width (a billboard has none; a model does).
const DEPTH_SHARE: float = 0.6

var _camera: Camera3D
var _fighters: BattleFighters
var _pad: float = 0.0


func setup(camera: Camera3D, fighters: BattleFighters, pad: float) -> void:
	_camera = camera
	_fighters = fighters
	_pad = pad


## The screen rect of one fighter (a zero rect when the fighter or the camera is not there yet).
func of(unit_id: StringName) -> Rect2:
	var visual: CharacterVisual = _fighters.visual(unit_id)
	if visual == null or _camera == null or not _camera.is_inside_tree():
		return Rect2()
	var feet: Vector3 = visual.anchor_position(&"feet")
	var half: float = visual.width() / 2.0
	var points := PackedVector2Array()
	for side_x: float in [-1.0, 1.0]:
		for side_z: float in [-1.0, 1.0]:
			for top: float in [0.0, 1.0]:
				var corner: Vector3 = feet + Vector3(side_x * half, top * visual.height(), side_z * half * DEPTH_SHARE)
				if not _camera.is_position_behind(corner):
					points.append(_camera.unproject_position(corner))
	return HudLayout.bounds(points).grow(_pad)


## Every fighter's rect by unit id.
func all(unit_ids: Array[StringName]) -> Dictionary[StringName, Rect2]:
	var out: Dictionary[StringName, Rect2] = {}
	for unit_id: StringName in unit_ids:
		out[unit_id] = of(unit_id)
	return out
