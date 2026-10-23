class_name RooftopParty
extends RefCounted
## purpose: Manages party teleportation and save point placement on the rooftop.

static func teleport(player: Player, follower: Follower, director: PatrolDirector,
		camera_rig: FollowCameraRig, aim: RooftopCamera, pos: Vector3, grace: bool = true) -> void:
	player.position = pos
	follower.stand_by_player()
	if grace and director != null:
		director.hold_all()
	if camera_rig != null and not camera_rig.is_intro_playing() and aim != null:
		camera_rig.update(Rooftop.SNAP_SECONDS, aim.subject(pos))


static func place(area: AreaDef, floor_y: float, save_point: StringName,
		teleport_fn: Callable) -> void:
	var target: PlaceDef = area.place(save_point) if save_point != &"" else null
	var valid: bool = target != null and area.is_walkable(target.cell.x, target.cell.y)
	teleport_fn.call(area.spawn_position_for(save_point, floor_y), valid)
