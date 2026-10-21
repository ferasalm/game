class_name Rooftop
extends Node3D
## The rooftop exploration scene. Builds the night diorama from content (look, sky, mist, area, tiles), walks Zayd
## with Bilqis in tow, runs a Concession patrol and the workshop bench, and moves the camera through an ExploreCamera
## (follow, vista zone, opening shot).
## Battle and menu scenes use only the public API: encounter_touched, workshop_opened, set_exploring,
## reset_patrol, battle_anchor, restore_camera, play_intro. Actors are direct children, so their positions are area positions.

## The patrol touched the player. from_behind: it came from behind the way he faces (the ambush rule).
signal encounter_touched(encounter_id: StringName, from_behind: bool)
## The player pressed interact at the workshop bench.
signal workshop_opened
## The player opened a chest (named in the area's props); nothing is saved here, the owner of the inventory listens.
signal chest_opened(chest_id: StringName)

const RIG_ID: StringName = &"explore"

@export var area_id: StringName = &"souq_rooftops"
@export var look_id: StringName = &"night"

var player: Player
var follower: Follower
var patrol: Patrol
var workshop: WorkshopSpot
var dressing: AreaDressing
var camera: Camera3D
var blocks: Node3D
var camera_rig: ExploreCamera

var _rules: ExploreRulesDef
var _look: LookDef
var _area: AreaDef
var _floor_y: float = 0.0
var _anchor: Vector3 = Vector3.ZERO
var _locked: bool = false
var _ambush: int = 0
var _fps_label: Label
var _name_label: Label
var _debug_layer: CanvasLayer  ## FPS + area name; hidden until F3 (the area card shows the name to players)


func _ready() -> void:
	_rules = ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	_look = ContentDB.get_def("look", look_id) as LookDef
	_area = ContentDB.get_def("area", area_id) as AreaDef
	var rig := ContentDB.get_def("camera_rig", RIG_ID) as CameraRigDef
	if _rules == null or _look == null or _area == null or rig == null:
		push_error("Rooftop: missing explore rules, look, area or camera content")
		return
	var spawn: Vector2i = _area.find_marker(AreaDef.SPAWN)
	var floor_tile := ContentDB.get_def("tile", _area.tile_id_at(spawn.x, spawn.y)) as TileDef
	_floor_y = floor_tile.height
	_build_world(rig)
	_build_actors()
	_build_ui()
	_anchor = player.position


## Off: player, follower and patrol stop and hide, input is ignored. On: everything shows and resumes, and a new
## touch can fire.
func set_exploring(on: bool) -> void:
	if on:
		_locked = false
	else:
		camera_rig.skip_intro(true)
	player.set_active(on)
	follower.set_active(on)
	patrol.set_active(on)
	workshop.set_active(on)
	dressing.set_active(on)
	_name_label.visible = on


## The opening establishing shot (moon and clouds, then down to Zayd). The actors stand frozen until it ends or any
## key or click skips it.
func play_intro() -> void:
	_freeze_actors(true)
	camera_rig.play_intro()


## The patrol goes back to its start, hidden and harmless for the respawn time, then walks again.
func reset_patrol() -> void:
	patrol.reset()


## The floor point where a battle should be staged: where the last touch happened.
func battle_anchor() -> Vector3:
	return _anchor


## Who struck first at the last touch: 1 the patrol came at the player from behind, 2 the player came at the patrol
## from behind, 0 neither (and before any touch).
func last_touch_ambush() -> int:
	return _ambush


## Makes the follow camera the current one again.
func restore_camera() -> void:
	camera.make_current()


func _process(delta: float) -> void:
	if _debug_layer.visible:
		_fps_label.text = tr("UI_FPS") % Engine.get_frames_per_second()
	camera_rig.update(delta, player.position)


func _build_world(rig: CameraRigDef) -> void:
	add_child(Diorama.make_environment(_look))
	add_child(Diorama.make_sun(_look))
	blocks = AreaBuilder.build(_area, _rules)
	add_child(blocks)
	add_child(MistBuilder.build_area(_area))
	add_child(SkylineBuilder.build(_area))
	camera = Diorama.make_camera(_look)
	add_child(camera)
	camera.make_current()
	camera_rig = ExploreCamera.new()
	add_child(camera_rig)
	camera_rig.setup(camera, _look, rig, _area.vista_world(), _rules.camera_smoothing, _marker(AreaDef.SPAWN))
	camera_rig.intro_finished.connect(_freeze_actors.bind(false))


func _freeze_actors(frozen: bool) -> void:
	var mode: Node.ProcessMode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	for actor: Node in [player, follower, patrol, workshop]:
		actor.process_mode = mode
	for chest: Chest in dressing.chests:
		chest.process_mode = mode


func _build_actors() -> void:
	player = Player.new(_rules)
	player.position = _marker(AreaDef.SPAWN)
	add_child(player)
	follower = Follower.new(_rules, player)
	add_child(follower)
	patrol = Patrol.new(_rules, _marker(AreaDef.PATROL_START), _marker(AreaDef.PATROL_END), player)
	patrol.touched.connect(_on_touched)
	add_child(patrol)
	workshop = WorkshopSpot.new(_rules, player)
	workshop.position = _marker(AreaDef.WORKSHOP)
	workshop.opened.connect(workshop_opened.emit)
	add_child(workshop)
	dressing = AreaDressing.build(_area, _rules, player, _floor_y)
	for chest: Chest in dressing.chests:
		chest.opened.connect(chest_opened.emit)
	add_child(dressing)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.visible = false
	_debug_layer = layer
	_fps_label = _label(layer, Vector2(16.0, 16.0))
	_name_label = _label(layer, Vector2(16.0, 56.0))
	_name_label.text = tr(_area.name_key)
	add_child(layer)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F3:
		_debug_layer.visible = not _debug_layer.visible


func _label(layer: CanvasLayer, pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", 28)
	layer.add_child(label)
	return label


func _marker(marker: String) -> Vector3:
	return AreaBuilder.cell_center(_area.find_marker(marker)) + Vector3(0.0, _floor_y, 0.0)


func _on_touched(from_behind: bool) -> void:
	if _locked:
		return
	_locked = true
	_ambush = _ambush_side(from_behind)
	_anchor = player.position.lerp(patrol.position, 0.5)
	encounter_touched.emit(_area.encounter, from_behind)


func _ambush_side(from_behind: bool) -> int:
	if from_behind:
		return 1
	var to_player: Vector3 = player.position - patrol.position
	to_player.y = 0.0
	return 2 if to_player.dot(patrol.facing()) < 0.0 else 0
