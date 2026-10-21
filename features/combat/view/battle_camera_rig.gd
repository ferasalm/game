class_name BattleCameraRig
extends RefCounted
## Builds a BattleStage's camera: the Camera3D with the arena's Environment and the cinematic BattleCamera that moves
## it, and the painted look's ink outline and grade on top. Sets stage.look, camera and camera_rig.


static func add_to(stage: BattleStage, anchor: Vector3) -> void:
	if stage.look == null:
		stage.look = ContentDB.get_def("look", &"night") as LookDef
	if stage.look == null:
		stage.look = LookDef.new()
	var def := ContentDB.get_def("battle_camera", &"default") as BattleCameraDef
	stage.camera = Diorama.make_camera(stage.look)
	stage.camera.environment = stage.environment
	stage.add_child(stage.camera)
	stage.camera_rig = BattleCamera.new()
	stage.add_child(stage.camera_rig)
	stage.camera_rig.setup(stage.camera, def if def != null else BattleCameraDef.new(), stage.look, anchor, null,
		stage.instant)
	stage.camera.current = true  # no previous camera: the arena is far from the exploring area


## A painted look gives the fight its ink outline, grade and vignette, like the area it left.
static func paint(stage: BattleStage) -> void:
	if stage.environment != null and stage.look != null and stage.look.paint != null:
		PaintedLook.finish(stage, stage.look, stage.environment, stage.camera, null)
