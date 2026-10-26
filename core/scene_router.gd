extends Node
## Game flow owner (autoload Router): title, new game, save and load, busy state, unstuck, and the play-time clock.
## Screens and menus call only these methods and signals (docs/ARCHITECTURE.md section 9). A battle host reads
## EventBus.battle_requested and owns its own view; the Router no longer builds or returns from a battle.

signal flow_changed(state: StringName)

const STATE_TITLE: StringName = &"title"
const STATE_EXPLORING: StringName = &"exploring"
const STATE_BATTLE: StringName = &"battle"
const STATE_BUSY: StringName = &"busy"
const MIN_TIME_SCALE: float = 0.001  ## guards the real-time division

var state: StringName = STATE_TITLE
## Where saves live; empty delegates to SaveService.default_dir. Tests point this at a scratch folder.
var save_dir: String = ""
## The slot last saved or loaded (not in the save itself; starts at 1).
var last_slot: int = 1
## Replaces reloading the current scene on new game / load / title (tests set a recording Callable).
var scene_reloader: Callable = Callable()
var _skip_title: bool = false


func _process(delta: float) -> void:
	tick(delta)


## Adds game time while the game runs and is not paused. Real seconds: a hitstop's low time scale does not count.
func tick(delta: float) -> void:
	if state == STATE_TITLE or get_tree().paused:
		return
	GameState.play_seconds += delta / maxf(Engine.time_scale, MIN_TIME_SCALE)


func is_exploring() -> bool:
	return state == STATE_EXPLORING

func enter_title() -> void:
	_set_state(STATE_TITLE)

func enter_exploring() -> void:
	_set_state(STATE_EXPLORING)


## Dialogue or a workshop menu is up: the pause menu and saving wait (on) or are allowed again (off).
func set_busy(on: bool) -> void:
	if on and state == STATE_EXPLORING:
		_set_state(STATE_BUSY)
	elif not on and state == STATE_BUSY:
		_set_state(STATE_EXPLORING)


## True only while exploring with no screen open.
func can_save() -> bool:
	return state == STATE_EXPLORING and not Screens.is_open()


func has_save(slot: int) -> bool:
	return RouterSaves.has_save(save_dir, slot)


func has_any_save() -> bool:
	return RouterSaves.has_any_save(save_dir)


func newest_slot() -> int:
	return RouterSaves.newest_slot(save_dir)


## Writes the game to a slot. Returns "" or the reason it failed. The caller checks can_save (the sabil saves
## from its own screen).
func save_slot(slot: int) -> String:
	var err: String = RouterSaves.save_slot(save_dir, slot)
	if err.is_empty():
		last_slot = slot
	return err


## Loads a slot (its backup when the file is damaged) and restarts the area from it. Returns "" or the reason.
func load_slot(slot: int) -> String:
	var result: Array = RouterSaves.load_slot_data(save_dir, slot)
	var data: Dictionary = result[0]
	var err: String = result[1]
	if not err.is_empty():
		return err
	var problem: String = GameState.from_dict(data)
	if problem.is_empty():
		last_slot = slot
		_restart(true, STATE_BUSY)
	return problem


func new_game() -> void:
	GameState.start_new()
	_restart(true, STATE_BUSY)


func go_to_title() -> void:
	GameState.reset()
	_restart(false, STATE_TITLE)


## Without an area to return to, unstuck only leaves the busy state.
func unstuck() -> void:
	if state == STATE_BUSY:
		_set_state(STATE_EXPLORING)


func quit_game() -> void:
	get_tree().quit()


## True once after a restart that skips the title (new game, load): the area asks at startup.
func take_skip_title() -> bool:
	var skip: bool = _skip_title
	_skip_title = false
	return skip


## Closes every screen, then rebuilds the game from GameState (the new scene reads it).
func _restart(skip_title: bool, next_state: StringName) -> void:
	Screens.clear()
	get_tree().paused = false
	_skip_title = skip_title
	_set_state(next_state)
	if scene_reloader.is_valid():
		scene_reloader.call()
	elif get_tree().current_scene != null:
		get_tree().reload_current_scene()
	else:
		push_warning("Router: no current scene to reload")


func _set_state(next: StringName) -> void:
	if next != state:
		state = next
		flow_changed.emit(state)
