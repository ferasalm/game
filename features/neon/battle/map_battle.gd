class_name MapBattle
extends Node
## purpose: One turn-based fight on the iso map (docs/design/first-playable.md section 3, no arena swap): builds the
## BattleSim from the room's encounter, glitches and letterboxes in, runs the fighters to MapFormation spots, plays
## the sim in wait mode with the existing command menu, then pays the victory or offers Retry / Quit.

signal ended(won: bool)

const HERO_ID: StringName = &"zayd"

var sim: BattleSim
var room: NeonRoomDef
var actors: Dictionary[StringName, IsoActor] = {}
var shown_hp: Dictionary[StringName, int] = {}
var hud: MapBattleHud
var view: NeonBattleViewDef
## Headless tests: no tweens, no waits; the loop plays each batch synchronously.
var instant: bool = false
## The hero chooses through sim.auto_choose (tests and the demo).
var auto_play: bool = false

var _world: Node2D
var _loader: BattleLoader
var _battle_view: BattleViewDef
var _play: MapBattlePlay
var _menu: BattleCommandMenu
var _hero: IsoActor
var _foes: Array[IsoActor] = []
var _contact: Vector2
var _hero_spot: Vector2
var _foe_spots: Array[Vector2] = []
var _seed: int = 1
var _busy: bool = false
var _ending: bool = false
var _done: bool = false
var _pre_vitals: Dictionary = {}
var _pre_bag: Dictionary = {}
var _pre_money: int = 0


func begin(world: Node2D, new_room: NeonRoomDef, hero: IsoActor, foes: Array[IsoActor],
		contact: Vector2, ambush: bool) -> void:
	_world = world
	room = new_room
	_hero = hero
	_foes = foes
	_contact = contact
	view = ContentDB.get_def("neon_battle_view", &"default") as NeonBattleViewDef
	if view == null:
		view = NeonBattleViewDef.new()
	_seed = randi()
	_pre_vitals = GameState.vitals.duplicate(true)
	_pre_bag = GameState.bag.duplicate()
	_pre_money = GameState.money
	_build(ambush)
	_busy = true
	if instant:
		MapBattleBuild.place(self)
		_busy = false
		_check_end()
	else:
		MapBattleIntro.play(self)


## Test helper: drives the instant loop synchronously until the sim ends or max_frames pass.
func run_to_end(max_frames: int) -> StringName:
	var frames: int = 0
	while sim != null and sim.result == &"" and frames < max_frames:
		step_frame()
		frames += 1
	_check_end()
	return sim.result


func step_frame() -> void:
	if sim == null or _busy or _done or sim.result != &"":
		return
	var hero: UnitState = sim.waiting_hero()
	if hero != null and not auto_play:
		_open_menu(hero)
		return
	if hero != null:
		sim.auto_choose(hero)
	if instant:
		_play.play(_tick_batch())
		_check_end()
		return
	_busy = true
	await _play.play(_tick_batch())
	_busy = false
	_check_end()


## A small camera shake on the map node (the plate and actors move together).
func shake() -> void:
	if instant or _world == null:
		return
	var home: Vector2 = _world.position
	var tween: Tween = create_tween()
	for i: int in 3:
		tween.tween_property(_world, "position", home + Vector2(view.shake, -view.shake), view.shake_seconds * 0.25)
		tween.tween_property(_world, "position", home - Vector2(view.shake, view.shake), view.shake_seconds * 0.25)
	tween.tween_property(_world, "position", home, view.shake_seconds * 0.25)


func _process(_delta: float) -> void:
	if not instant:
		step_frame()


func _build(ambush: bool) -> void:
	MapBattleBuild.build(self, ambush)


func _tick_batch() -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	for i: int in _battle_view.ticks_per_frame:
		events.append_array(sim.step())
		if sim.result != &"" or sim.waiting_hero() != null:
			break
	return events


func _open_menu(hero: UnitState) -> void:
	if _menu == null:
		_menu = BattleCommandMenu.new()
		hud.add_child(_menu)
		_menu.setup(sim, _battle_view)
		_menu.chosen.connect(_on_chosen)
		var screen: Vector2 = get_viewport().get_visible_rect().size
		_menu.position = Vector2(screen.x - 440.0, screen.y - 420.0)
	if not _menu.is_open():
		_menu.open(hero)


func _on_chosen(action: ActionDef, target_id: StringName) -> void:
	var hero: UnitState = sim.waiting_hero()
	if hero == null:
		return
	var reason: String = sim.choose(hero.unit_id, action, target_id)
	if reason.is_empty():
		_menu.close()
	else:
		_menu.show_notice(reason)


func _check_end() -> void:
	if sim == null or sim.result == &"" or _ending:
		return
	_ending = true
	if _menu != null:
		_menu.close()
	var won: bool = sim.result == &"victory"
	MapBattleBuild.pose_winner(self, won)
	hud.refresh()
	if won:
		var paid: Array[int] = MapBattleEnd.award(self)
		hud.show_victory(paid[0], paid[1])
		if not instant:
			await hud.play_outro()
			await get_tree().create_timer(1.2).timeout
		_finish(true)
		return
	if not instant:
		await hud.play_outro()
	hud.show_defeat()


func _on_retry() -> void:
	MapBattleEnd.retry(self)


func _on_quit() -> void:
	_finish(false)


func _finish(won: bool) -> void:
	if _done:
		return
	_done = true
	ended.emit(won)
