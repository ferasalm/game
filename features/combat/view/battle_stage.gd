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
## When set, the battle camera renders with this Environment instead of the scene's WorldEnvironment (the Router
## gives the arena its own, so the exploring area's environment is overridden).
var environment: Environment
## The arena's look (the runner sets it before start); null falls back to the night look.
var look: LookDef
## The frame the area showed when the fight began, for the shatter warp in (null: no warp).
var warp_frame: Image
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
	BattleCameraRig.add_to(self, anchor)
	_add_show()
	hud = BattleHud.new()
	add_child(hud)
	hud.setup(sim, _view, shown_hp)
	BattleCameraRig.paint(self)
	hud.move_chosen.connect(_on_move_chosen)
	hud.item_chosen.connect(_on_item_chosen)
	hud.target_focused.connect(_on_target_focused)
	hud.end_chosen.connect(_finish)
	_player = BattleEventPlayer.new()
	add_child(_player)
	_player.setup(sim, _view, fighters, hud, shown_hp)
	_player.attach(_actions, juice, vfx)
	_busy = true
	if sim.ambush == 1:
		_turn_wielder_away()
	if not instant and BattleShatter.can_play(warp_frame):
		await _warp_in()
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
	if sim.result == &"defeat" and not auto_play and BattleEnding.open_defeat(_finish):
		return
	hud.show_end(sim.result)
	if auto_play:
		if not instant:
			await PauseWait.seconds(self, _view.end_delay + _view.banner_seconds)
		_finish(sim.result)


## The fight is over with this answer: &"victory" / &"defeat" (back to the rooftop, after the light wash), &"retry",
## &"load" or &"title" (the Defeat screen's picks).
func _finish(result: StringName) -> void:
	if _finished:
		return
	_finished = true
	if instant or auto_play or not BattleEnding.washes(result):
		ended.emit(result)
	else:
		BattleEnding.wash(self, ended.emit.bind(result))


## The area's last frame breaks into glass over the arena (the opening waits for it).
func _warp_in() -> void:
	var shatter := BattleShatter.new()
	add_child(shatter)
	await shatter.play(warp_frame, juice.def)


func _on_move_chosen(action: ActionDef, target_id: StringName) -> void:
	var hero: UnitState = sim.waiting_hero()
	if hero == null:
		return
	var reason: String = sim.choose(hero.unit_id, action, target_id)
	if reason.is_empty():
		hud.close_menu()
	else:
		hud.menu.show_notice(reason)


func _on_item_chosen(item_id: StringName, target_id: StringName) -> void:
	var hero: UnitState = sim.waiting_hero()
	if hero == null:
		return
	var reason: String = sim.choose_item(hero.unit_id, item_id, target_id)
	if reason.is_empty():
		hud.close_menu()
	else:
		hud.item_menu.show_notice(reason)


func _on_target_focused(unit_id: StringName) -> void:
	if unit_id == &"":
		fighters.hide_marker()
	else:
		fighters.point_at(unit_id)


func _turn_wielder_away() -> void:
	fighters.face_foes(Jambiyah.WIELDER, true)


## The effect painter, the hitstop / shake node and the move player that drives them.
func _add_show() -> void:
	vfx = VfxPlayer.new()
	add_child(vfx)
	vfx.warm_up()
	juice = BattleJuice.new()
	add_child(juice)
	juice.setup(ContentDB.get_def("battle_juice", &"default") as JuiceDef, camera_rig)
	_actions = BattleActionPlayer.new()
	add_child(_actions)
	_actions.setup(fighters, vfx, camera_rig, juice)
