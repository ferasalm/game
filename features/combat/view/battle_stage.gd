class_name BattleStage
extends Node3D
## The battle screen (wait mode): places the fighters and the camera, runs the HUD, steps a BattleSim a few
## ticks per physics frame and plays the resulting events. Needs to be in the scene tree at origin before start().
## Result of the battle goes out through `ended`: &"victory", &"defeat" (back to the rooftop) or &"retry".

signal ended(result: StringName)

## Heroes choose through sim.auto_choose (tests and demo); the end panel does not wait for a click.
var auto_play: bool = false
## Skip every animation and wait (headless tests); events then play synchronously.
var instant: bool = false
var sim: BattleSim
var fighters: BattleFighters
var hud: BattleHud
var camera: Camera3D
## The cinematic rig that moves `camera` (swoop in, drift, push, shake, victory pose).
var camera_rig: BattleCamera
var vfx: VfxPlayer
var juice: BattleJuice
## HP as the played events show it (the sim is already one batch ahead).
var shown_hp: Dictionary[StringName, int] = {}
var _view: BattleViewDef
var _player: BattleEventPlayer
var _actions: BattleActionPlayer
var _busy: bool = false
var _ending: bool = false
var _finished: bool = false


func start(battle: BattleSim, anchor: Vector3) -> void:
	sim = battle
	_view = ContentDB.get_def("battle_view", &"default") as BattleViewDef
	if _view == null:
		push_error("BattleStage: content/combat/view.json has no 'default' battle_view")
		return
	for unit: UnitState in sim.timeline.units:
		shown_hp[unit.unit_id] = unit.hp
	fighters = BattleFighters.new()
	add_child(fighters)
	fighters.build(sim, _view, anchor)
	_add_camera(anchor)
	_add_show()
	hud = BattleHud.new()
	add_child(hud)
	hud.setup(sim, _view, shown_hp)
	hud.move_chosen.connect(_on_move_chosen)
	hud.target_focused.connect(_on_target_focused)
	hud.end_chosen.connect(_finish)
	_player = BattleEventPlayer.new()
	add_child(_player)
	_player.setup(sim, _view, fighters, hud, shown_hp)
	_player.attach(_actions, juice, vfx)
	_busy = true
	if sim.ambush == 1:
		_turn_zayd_away()
	await _player.play(sim.opening(), instant)
	_busy = false
	_check_end()


## Test helper: drives the loop synchronously (needs `instant`; heroes need `auto_play`) until the battle ends,
## a hero waits for the menu, or max_frames pass. Returns the sim's result (&"" if unfinished).
func run_to_end(max_frames: int) -> StringName:
	var frames: int = 0
	while sim.result == &"" and frames < max_frames and not hud.menu.is_open():
		step_frame()
		frames += 1
	return sim.result


func _physics_process(_delta: float) -> void:
	step_frame()


## One frame of the loop: nothing while events play; a waiting hero gets the menu (or the AI); else tick the sim.
func step_frame() -> void:
	if sim == null or _busy or _finished or sim.result != &"":
		return
	var hero: UnitState = sim.waiting_hero()
	if hero != null and not auto_play:
		if not hud.menu.is_open():
			hud.open_menu(hero)
		return
	if hero != null:
		sim.auto_choose(hero)
	_busy = true
	await _player.play(_tick_batch(), instant)
	_busy = false
	_check_end()


func _tick_batch() -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	for i: int in _view.ticks_per_frame:
		events.append_array(sim.step())
		if sim.result != &"" or sim.waiting_hero() != null:
			break
	return events


func _check_end() -> void:
	if sim.result == &"" or _ending:
		return
	_ending = true
	fighters.hide_marker()
	if sim.result == &"victory":
		camera_rig.victory()
		fighters.cheer()
	hud.show_end(sim.result)
	if auto_play:
		if not instant:
			await get_tree().create_timer(_view.end_delay + _view.banner_seconds).timeout
		_finish(sim.result)


func _finish(result: StringName) -> void:
	if _finished:
		return
	_finished = true
	ended.emit(result)


func _on_move_chosen(action: ActionDef, target_id: StringName) -> void:
	var hero: UnitState = sim.waiting_hero()
	if hero == null:
		return
	var reason: String = sim.choose(hero.unit_id, action, target_id)
	if reason.is_empty():
		hud.close_menu()
	else:
		hud.menu.show_notice(reason)


func _on_target_focused(unit_id: StringName) -> void:
	if unit_id == &"":
		fighters.hide_marker()
	else:
		fighters.point_at(unit_id)


func _turn_zayd_away() -> void:
	var zayd: CharacterVisual = fighters.visual(&"zayd")
	if zayd != null:
		zayd.face(-1.0)


func _add_camera(anchor: Vector3) -> void:
	var look := ContentDB.get_def("look", &"night") as LookDef
	if look == null:
		look = ContentDB.get_def("look", &"v1") as LookDef
	var def := ContentDB.get_def("battle_camera", &"default") as BattleCameraDef
	var previous: Camera3D = get_viewport().get_camera_3d()
	camera = Diorama.make_camera(look if look != null else LookDef.new())
	add_child(camera)
	camera_rig = BattleCamera.new()
	add_child(camera_rig)
	camera_rig.setup(camera, def if def != null else BattleCameraDef.new(), look if look != null else LookDef.new(),
		anchor, previous, instant)
	camera.current = true


## The effect painter, the hitstop / shake node and the move player that drives them.
func _add_show() -> void:
	vfx = VfxPlayer.new()
	add_child(vfx)
	juice = BattleJuice.new()
	add_child(juice)
	juice.setup(ContentDB.get_def("battle_juice", &"default") as JuiceDef, camera_rig)
	_actions = BattleActionPlayer.new()
	add_child(_actions)
	_actions.setup(fighters, vfx, camera_rig, juice)
