class_name RooftopCamera
extends RefCounted
## What the exploration camera looks at: the player clamped into the rig's limits (so it never leaves the commons),
## or, during dialogue, the speaker's head. Rooftop asks subject() every frame and hands it to the ExploreCamera.

var _rig: CameraRigDef
var _look_height: float
var _speaker: CharacterVisual = null
var _speaker_node: Node3D = null


func _init(rig: CameraRigDef, look: LookDef) -> void:
	_rig = rig
	_look_height = rig.pose_for(look).look_height


## Frames a speaker: &"zayd", &"bilqis", or a bystander's place id or sprite id. False when nobody here has that id.
func frame(speaker_id: StringName, actors: AreaActors) -> bool:
	var node: Node3D = null
	var visual: CharacterVisual = null
	if speaker_id == &"zayd":
		node = actors.player
		visual = actors.player.visual()
	elif speaker_id == &"bilqis":
		node = actors.follower
		visual = actors.follower.visual()
	else:
		for i: int in actors.bystanders.size():
			var place: PlaceDef = actors.bystander_places[i]
			if place.id == speaker_id or place.sprite == speaker_id:
				node = actors.bystanders[i]
				visual = actors.bystanders[i].visual()
	if node == null:
		return false
	_speaker_node = node
	_speaker = visual
	return true


func clear_speaker() -> void:
	_speaker_node = null
	_speaker = null


func is_framing() -> bool:
	return _speaker_node != null


## The point the camera follows this frame (the head anchor's height replaces the feet height while framing).
func subject(player_pos: Vector3) -> Vector3:
	var point: Vector3 = player_pos
	if _speaker_node != null and is_instance_valid(_speaker_node):
		point = _speaker_node.position
		if _speaker != null and is_instance_valid(_speaker):
			point.y = _speaker.anchor_position(&"head").y - _look_height
	return CameraLimits.clamp_target(point, _rig.limit_x, _rig.limit_z)
