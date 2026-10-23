class_name Rooftop
extends Node3D
## The rooftop exploration scene: builds the diorama (RooftopWorld), the actors (AreaActors) and the patrol rules
## (PatrolDirector); battle and menu scenes use only the public API below. Actors are direct children: their
## positions are area positions.

## A patrol touched the player. from_behind: it came from behind the way he faces (the ambush rule).
signal encounter_touched(encounter_id: StringName, from_behind: bool)
## The player pressed interact at the workshop bench.
signal workshop_opened
## The player opened a chest (named in the area's props); nothing is saved here, the owner of the inventory listens.
signal chest_opened(chest_id: StringName)

const RIG_ID: StringName = &"explore"
## A frame length long enough that the camera's smoothing finishes in one update (a jump cut).
const SNAP_SECONDS: float = 100.0

@export var area_id: StringName = &"souq_rooftops"
@export var look_id: StringName = &"painted_b"

var player: Player
var follower: Follower
## The first patrol (kept for callers that know one patrol), and all of them.
var patrol: Patrol
var patrols: Array[Patrol] = []
var workshop: WorkshopSpot
var stall: StallSpot
var sabil: SabilSpot
var talk_spots: Array[TalkSpot] = []
var dressing: AreaDressing
var camera: Camera3D
var blocks: Node3D
var camera_rig: FollowCameraRig

var _actors: AreaActors
var _rules: ExploreRulesDef
var _look: LookDef
var _env: WorldEnvironment
var _area: AreaDef
var _floor_y: float = 0.0
var _anchor: Vector3 = Vector3.ZERO
var _locked: bool = false
var _exploring: bool = true
var _ambush: int = 0
var _director: PatrolDirector
var _flow: FlowRulesDef
var _safety: RooftopSafety
var _aim: RooftopCamera
var _debug: RooftopDebug

func _ready() -> void:
	_rules = ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	_look = ContentDB.get_def("look", PaintedLook.pick(look_id)) as LookDef
	_area = ContentDB.get_def("area", area_id) as AreaDef
	_flow = ContentDB.get_def("flow_rules", &"default") as FlowRulesDef
	var rig := ContentDB.get_def("camera_rig", RIG_ID) as CameraRigDef
	if _rules == null or _look == null or _area == null or rig == null or _flow == null:
		push_error("Rooftop: missing explore rules, flow rules, look, area or camera content")
		return
	_floor_y = AreaWalk.floor_height(_area)
	_aim = RooftopCamera.new(rig, _look)
	var world: RooftopWorld = RooftopWorld.build(self, _area, _rules, _look, rig,
		AreaActors.marker_of(_area, AreaDef.SPAWN, _floor_y))
	_env = world.env
	blocks = world.blocks
	camera = world.camera
	camera_rig = world.camera_rig
	camera_rig.intro_finished.connect(freeze_actors.bind(false))
	_build_actors()
	camera_rig.set_actors(player, follower)
	camera_rig.set_zones(_area.places_of(&"camera_zone"))
	_debug = RooftopDebug.new()
	_debug.setup(_flow, tr(_area.name_key))
	add_child(_debug)
	PaintedLook.finish(self, _look, _env.environment, camera, player)
	_anchor = player.position
	_safety = RooftopSafety.for_area(_area, _rules, _flow, player.position)
	_director.sync_cleared()


## Off: player, follower and patrols stop and hide, input is ignored. On: everything shows and resumes, and a new
## touch can fire.
func set_exploring(on: bool) -> void:
	_exploring = on
	if on:
		_locked = false
	else:
		camera_rig.skip_intro(true)
	for actor: Node in _actors.switchables():
		actor.call(&"set_active", on)
	dressing.set_active(on)
	_debug.set_name_visible(on)
	if on:
		_director.sync_cleared()


## The opening establishing shot; the actors stand frozen until it ends or any key or click skips it.
func play_intro() -> void:
	freeze_actors(true)
	camera_rig.play_intro()


## Called after every battle: patrols beaten (GameState.cleared_patrols) disappear; the one that fought goes back to
## its lane start; nobody can touch for touch_grace seconds; the party stands clear of every patrol.
func reset_patrol() -> void:
	_director.after_battle()
	teleport_party(_safety.return_spot(player.position, patrols), false)


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


## Where "unstuck" puts the party: the newest still spot clear of the patrols, else the nearest safe place.
func last_safe_position() -> Vector3:
	return _safety.unstuck_target(player.position, patrols)


## Moves Zayd to pos and Bilqis beside him (her trail restarts there) and the camera jumps to follow. Patrols
## cannot touch for touch_grace seconds (when grace is true).
func teleport_party(pos: Vector3, grace: bool = true) -> void:
	player.position = pos
	follower.stand_by_player()
	if grace:
		_director.hold_all()
	if not camera_rig.is_intro_playing():
		camera_rig.update(SNAP_SECONDS, _aim.subject(pos))


## Puts the party at a save point (a place id of this area); an unknown, empty or unwalkable id lands on spawn_start.
func place_party(save_point: StringName) -> void:
	var place: PlaceDef = _area.place(save_point)
	var valid: bool = place != null and _area.is_walkable(place.cell.x, place.cell.y)
	teleport_party(_area.spawn_position_for(save_point, _floor_y), valid)


## Dialogue framing: the camera looks at this speaker's head (&"zayd", &"bilqis", a bystander's place id or sprite).
## Returns false when nobody here has that id.
func frame_speaker(speaker_id: StringName) -> bool:
	return _aim.frame(speaker_id, _actors)


func clear_speaker() -> void:
	_aim.clear_speaker()


func _process(delta: float) -> void:
	camera_rig.update(delta, _aim.subject(player.position))
	if _exploring and not _locked:
		_safety.update(player.position, delta, patrols)


func freeze_actors(frozen: bool) -> void:
	var mode: Node.ProcessMode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	for actor: Node in _actors.switchables():
		actor.process_mode = mode
	for chest: Chest in dressing.chests:
		chest.process_mode = mode

func _build_actors() -> void:
	_actors = AreaActors.build(self, _area, _rules, _floor_y)
	player = _actors.player
	follower = _actors.follower
	patrols = _actors.patrols
	patrol = patrols[0] if not patrols.is_empty() else null
	_director = PatrolDirector.new(patrols, _rules.touch_grace)
	workshop = _actors.workshop
	stall = _actors.stalls[0] if not _actors.stalls.is_empty() else null
	sabil = _actors.sabil
	talk_spots = _actors.talk_spots
	for p: Patrol in patrols:
		p.touched.connect(_on_touched.bind(p))
	workshop.opened.connect(workshop_opened.emit)
	if sabil != null:
		sabil.drunk.connect(_director.after_drink)
	dressing = AreaDressing.build(_area, _rules, player, _floor_y)
	for chest: Chest in dressing.chests:
		chest.opened.connect(chest_opened.emit)
	add_child(dressing)

func _on_touched(from_behind: bool, source: Patrol) -> void:
	if _locked:
		return
	_locked = true
	_director.fought = source
	_ambush = _director.ambush_side(from_behind, player.position, source)
	_anchor = player.position.lerp(source.position, 0.5)
	encounter_touched.emit(source.encounter_id, from_behind)
