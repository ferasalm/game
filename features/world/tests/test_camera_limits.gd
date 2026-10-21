extends TestCase
## The exploration camera frame (docs/design/rooftop-v3.md section 2): CameraLimits maths, the limits in camera.json,
## and on the shipped rooftop for every walkable cell: the camera (pitch 35/45/55 x distance 14/17/20, and the shipped
## hades preset) never stands inside a building, a prop or a skyline tower of the near and mid bands.

const PITCHES: Array[float] = [35.0, 45.0, 55.0]
const DISTANCES: Array[float] = [14.0, 17.0, 20.0]
## Roof extras (water tank, antenna, dish) and the parapet add up to this much above floors * floor_height.
const ROOF_ALLOWANCE: float = 4.0
const CLEARANCE: float = 0.5
const APRON_TOP: float = 7.0


func _rig() -> CameraRigDef:
	return ContentDB.get_def("camera_rig", &"explore") as CameraRigDef


func _area() -> AreaDef:
	return ContentDB.get_def("area", &"souq_rooftops") as AreaDef


func test_clamp_target_keeps_the_frame_in_the_commons() -> void:
	var x := Vector2(7.5, 18.5)
	var z := Vector2(3.0, 14.0)
	check_eq(CameraLimits.clamp_target(Vector3(25.0, 0.5, 1.0), x, z), Vector3(18.5, 0.5, 3.0), "east roof and north strip clamp")
	check_eq(CameraLimits.clamp_target(Vector3(10.0, 0.5, 8.0), x, z), Vector3(10.0, 0.5, 8.0), "inside is untouched")
	check_eq(CameraLimits.clamp_target(Vector3(99.0, 0.5, 99.0), Vector2.ZERO, Vector2.ZERO), Vector3(99.0, 0.5, 99.0),
		"no limits: nothing clamps")


func test_camera_point_is_behind_and_above() -> void:
	var cam: Vector3 = CameraLimits.camera_point(Vector3(10.0, 0.5, 8.0), 45.0, 10.0, 0.8)
	check(is_equal_approx(cam.x, 10.0), "same x as the target")
	check(is_equal_approx(cam.y, 0.5 + 0.8 + 10.0 * sin(deg_to_rad(45.0))), "raised by look height and distance * sin(pitch)")
	check(is_equal_approx(cam.z, 8.0 + 10.0 * cos(deg_to_rad(45.0))), "pulled back by distance * cos(pitch)")


func test_inside_box() -> void:
	check(CameraLimits.inside_box(Vector3(1, 1, 1), Vector3.ZERO, Vector3(2, 2, 2), 0.0), "inside")
	check(not CameraLimits.inside_box(Vector3(2.4, 1, 1), Vector3.ZERO, Vector3(2, 2, 2), 0.3), "outside even with the margin")
	check(CameraLimits.inside_box(Vector3(2.2, 1, 1), Vector3.ZERO, Vector3(2, 2, 2), 0.3), "inside the margin")


func test_the_rig_ships_limits_for_the_commons() -> void:
	var rig: CameraRigDef = _rig()
	check(rig.has_limits(), "camera.json has limits")
	check_eq(rig.limit_x, Vector2(7.5, 18.5), "x range")
	check_eq(rig.limit_z, Vector2(3.0, 14.0), "z range")


func _boxes(area: AreaDef) -> Array[AABB]:
	var out: Array[AABB] = []
	for p: Placement in area.buildings:
		var def := ContentDB.get_def("building", p.ref) as BuildingDef
		out.append(_house(p.pos.x, p.pos.z, def, 0.0))
	for p: Placement in area.props:
		var def := ContentDB.get_def("prop", p.ref) as PropDef
		if def != null and def.collide != Vector3.ZERO:
			var reach: float = maxf(def.collide.x, def.collide.z)
			var base := Vector3(p.pos.x - reach / 2.0, p.pos.y if p.has_y else 0.5, p.pos.z - reach / 2.0)
			out.append(AABB(base, Vector3(reach, def.collide.y, reach)))
	return out


func _house(x: float, z: float, def: BuildingDef, ground: float) -> AABB:
	var top: float = def.floors * def.floor_height + ROOF_ALLOWANCE
	var size := Vector3(def.footprint_w, top, def.footprint_d)
	return AABB(Vector3(x - size.x / 2.0, ground, z - size.z / 2.0), size)


func _skyline_boxes(area: AreaDef) -> Array[AABB]:
	var def := ContentDB.get_def("skyline", &"old_city") as SkylineDef
	var footprints: Dictionary[StringName, Vector2] = {}
	for id: StringName in ContentDB.ids("building"):
		var b := ContentDB.get_def("building", id) as BuildingDef
		footprints[id] = Vector2(b.footprint_w, b.footprint_d)
	var out: Array[AABB] = []
	var blocks: Array[SkylineLayout.Block] = SkylineLayout.place(def, Rect2(0.0, 0.0, area.width(), area.depth()), footprints)
	for block: SkylineLayout.Block in blocks:
		if block.building == &"":
			continue
		var b := ContentDB.get_def("building", block.building) as BuildingDef
		var turned: bool = absf(sin(block.yaw)) > 0.5
		var swapped := BuildingDef.new()
		swapped.footprint_w = b.footprint_d if turned else b.footprint_w
		swapped.footprint_d = b.footprint_w if turned else b.footprint_d
		swapped.floors = b.floors
		swapped.floor_height = b.floor_height
		out.append(_house(block.position.x, block.position.z, swapped, def.ground_y))
	return out


func _reachable_cells(area: AreaDef) -> Array[Vector3]:
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	var reach: Dictionary[Vector2i, bool] = AreaWalk.build(area, rules).reachable(area.find_marker(AreaDef.SPAWN))
	return AreaWalk.centers(reach, AreaWalk.floor_height(area))


func _entered(point: Vector3, boxes: Array[AABB]) -> int:
	var count: int = 0
	for box: AABB in boxes:
		count += 1 if CameraLimits.inside_box(point, box.position, box.end, CLEARANCE) else 0
	return count


func test_no_camera_pose_enters_a_building_or_prop() -> void:
	var area: AreaDef = _area()
	var rig: CameraRigDef = _rig()
	var boxes: Array[AABB] = _boxes(area)
	var bad: int = 0
	var worst: Vector3 = Vector3.ZERO
	for cell: Vector3 in _reachable_cells(area):
		var target: Vector3 = CameraLimits.clamp_target(cell, rig.limit_x, rig.limit_z)
		for pitch: float in PITCHES:
			for distance: float in DISTANCES:
				var cam: Vector3 = CameraLimits.camera_point(target, pitch, distance, 0.8)
				if _entered(cam, boxes) > 0:
					bad += 1
					worst = cam
	check_eq(bad, 0, "camera poses inside a building or prop (e.g. %s)" % str(worst))


func test_the_shipped_preset_clears_the_skyline_near_and_mid_bands() -> void:
	var area: AreaDef = _area()
	var rig: CameraRigDef = _rig()
	var look := ContentDB.get_def("look", &"painted_b") as LookDef
	var pose: CameraRigDef.Preset = rig.pose_for(look)
	var boxes: Array[AABB] = _skyline_boxes(area)
	var bad: int = 0
	for cell: Vector3 in _reachable_cells(area):
		var target: Vector3 = CameraLimits.clamp_target(cell, rig.limit_x, rig.limit_z)
		bad += _entered(target + pose.offset, boxes)
	check_eq(bad, 0, "painted_b camera inside a skyline tower")


func test_the_south_apron_stays_low() -> void:
	var area: AreaDef = _area()
	var low: int = 0
	for box: AABB in _skyline_boxes(area):
		var in_apron: bool = box.end.x > -2.0 and box.position.x < 28.0 and box.end.z > 18.0 and box.position.z < 36.0
		if in_apron and box.end.y > APRON_TOP:
			low += 1
	check_eq(low, 0, "skyline towers above %.1f m in the south apron (x -2..28, z 18..36)" % APRON_TOP)


func test_the_player_stays_in_frame_at_the_limits() -> void:
	var rig: CameraRigDef = _rig()
	var look := ContentDB.get_def("look", &"painted_b") as LookDef
	var pose: CameraRigDef.Preset = rig.pose_for(look)
	var half_width: float = pose.offset.length() * tan(deg_to_rad(pose.fov / 2.0)) * (16.0 / 9.0)
	for cell: Vector3 in _reachable_cells(_area()):
		var target: Vector3 = CameraLimits.clamp_target(cell, rig.limit_x, rig.limit_z)
		check(absf(cell.x - target.x) < half_width, "cell %s stays inside the frame width (%.1f)" % [cell, half_width])


func test_the_entry_probe_catches_a_camera_inside_a_building() -> void:
	var tower: Array[AABB] = [AABB(Vector3(0.0, 0.0, 0.0), Vector3(4.0, 12.0, 4.0))]
	var inside: Vector3 = CameraLimits.camera_point(Vector3(2.0, 0.5, -9.0), 35.0, 14.0, 0.8)
	check_eq(_entered(inside, tower), 1, "a camera behind a tall tower pose is caught")
	check_eq(_entered(Vector3(9.0, 9.0, 9.0), tower), 0, "a camera well away is not")
