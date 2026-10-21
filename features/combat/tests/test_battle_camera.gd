extends TestCase
## The cinematic battle camera: it frames the stage from a low angle (12-16 degrees down), starts at the
## exploration camera and swoops to the battle pose, then drifts, follows, pushes in, shakes and glides to the
## victory pose, all from content/combat/camera.json. The stage uses it, and number pops and BREAK stamps exist.


func _rig(previous: Camera3D, instant: bool) -> BattleCamera:
	var look := ContentDB.get_def("look", &"night") as LookDef
	var camera := Diorama.make_camera(look)
	tree.root.add_child(camera)
	var rig := BattleCamera.new()
	tree.root.add_child(rig)
	rig.setup(camera, ContentDB.get_def("battle_camera", &"default") as BattleCameraDef, look, Vector3.ZERO, previous, instant)
	return rig


func _free(rig: BattleCamera) -> void:
	rig.camera.free()
	rig.free()


func test_low_angle() -> void:
	var def := ContentDB.get_def("battle_camera", &"default") as BattleCameraDef
	var pitch: float = rad_to_deg(atan((def.pos.y - def.look.y) / (def.pos.z - def.look.z)))
	check(pitch >= 12.0 and pitch <= 16.0, "pitch %.1f degrees down" % pitch)
	check(def.swoop_time > 0.5 and def.swoop_time < 1.5, "a swoop of about a second")


func test_instant_sits_at_the_battle_pose() -> void:
	var rig: BattleCamera = _rig(null, true)
	var def := ContentDB.get_def("battle_camera", &"default") as BattleCameraDef
	check(not rig.is_swooping(), "no swoop")
	check(rig.camera.position.distance_to(def.pos) < 0.01, "at the pose")
	_free(rig)


func test_swoop_from_the_exploration_camera() -> void:
	var explore := Camera3D.new()
	tree.root.add_child(explore)
	explore.position = Vector3(10.0, 6.0, 8.0)
	var rig: BattleCamera = _rig(explore, false)
	var def := ContentDB.get_def("battle_camera", &"default") as BattleCameraDef
	check(rig.is_swooping(), "swooping")
	check(rig.camera.position.distance_to(explore.position) < 0.01, "starts where the exploration camera was")
	for i: int in 90:
		rig._process(1.0 / 60.0)
	check(not rig.is_swooping(), "arrived after about a second")
	check(rig.camera.position.distance_to(def.pos) < 0.6, "at the battle pose (drift aside)")
	explore.free()
	_free(rig)


func test_follow_push_shake_and_victory() -> void:
	var rig: BattleCamera = _rig(null, true)
	var rest: Vector3 = rig.camera.position
	rig.focus_on(-3.0)
	rig.push(0.1, 1.0)
	for i: int in 60:
		rig._process(1.0 / 60.0)
	check(rig.camera.position.x < rest.x - 0.1, "leans toward the actor on the left")
	check(rig.camera.fov < (ContentDB.get_def("battle_camera", &"default") as BattleCameraDef).fov, "pushes in")
	rig.shake(0.3, 8.0, 60.0)
	rig._process(0.01)
	check(rig._shake_offset().length() > 0.01, "shakes")
	for i: int in 120:
		rig._process(1.0 / 60.0)
	check(rig._shake_offset().length() < 0.01, "and settles")
	rig.victory()
	for i: int in 120:
		rig._process(1.0 / 30.0)
	check(rig.in_victory() and rig.camera.position.z < rest.z - 1.0, "glides closer for the victory")
	_free(rig)


func test_stage_uses_the_rig_and_pops_exist() -> void:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	stage.auto_play = true
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7, 0), Vector3.ZERO)
	check(stage.camera_rig != null and stage.camera_rig.camera == stage.camera, "the rig drives the stage camera")
	check(stage.vfx != null and stage.juice != null, "effects and juice are in place")
	var view := ContentDB.get_def("battle_view", &"default") as BattleViewDef
	var label: Label3D = BattleNumbers.pop(stage, "12", Vector3.ZERO, 40, Color.WHITE, 1.0, view, stage.juice.def, 0.0)
	check(label.is_inside_tree() and label.scale.x < 1.0, "a number starts small and pops")
	var stamp: Label3D = BattleNumbers.stamp(stage, "BREAK!", Vector3.ZERO, view, stage.juice.def)
	check(stamp.text == "BREAK!", "the stamp shows its text")
	stage.run_to_end(30000)
	check(stage.camera_rig.in_victory() == (stage.sim.result == &"victory"), "victory camera only after a win")
	stage.free()
