class_name StartSteps
extends RefCounted
## Pure state transitions for the Neon Glitch start flow (no nodes or tree).

const STATE_TITLE: StringName = &"TITLE"
const STATE_MENU: StringName = &"MENU"
const STATE_WINDOW_PUSH: StringName = &"WINDOW_PUSH"
const STATE_PICK: StringName = &"PICK"
const STATE_PANEL: StringName = &"PANEL"
const STATE_REACTION: StringName = &"REACTION"
const STATE_LAUNCH: StringName = &"LAUNCH"
const STATE_DONE: StringName = &"DONE"

const HERO_RYDAN: StringName = &"rydan"
const HERO_BILQIS: StringName = &"bilqis"

const DIFF_NORMAL: StringName = &"normal"
const DIFF_HARD: StringName = &"hard"

const MENU_NEW_GAME: int = 0
const MENU_CONTINUE: int = 1
const MENU_OPTIONS: int = 2
const MENU_QUIT: int = 3

var state: StringName = STATE_TITLE
var menu_cursor: int = MENU_NEW_GAME
var hero: StringName = HERO_RYDAN
var difficulty: StringName = DIFF_NORMAL
var quit_requested: bool = false


func press_any() -> StringName:
	if state == STATE_TITLE:
		state = STATE_MENU
	return state


func confirm() -> bool:
	match state:
		STATE_TITLE:
			state = STATE_MENU
			return true
		STATE_MENU:
			if menu_cursor == MENU_NEW_GAME:
				state = STATE_WINDOW_PUSH
				return true
			if menu_cursor == MENU_QUIT:
				quit_requested = true
				return true
			return false
		STATE_WINDOW_PUSH:
			state = STATE_PICK
			return true
		STATE_PICK:
			if hero == HERO_RYDAN:
				state = STATE_PANEL
				return true
			return false
		STATE_PANEL:
			state = STATE_REACTION
			return true
		STATE_REACTION:
			state = STATE_LAUNCH
			return true
		STATE_LAUNCH:
			state = STATE_DONE
			return true
	return false


func back() -> bool:
	match state:
		STATE_MENU:
			state = STATE_TITLE
			return true
		STATE_PICK:
			state = STATE_MENU
			return true
		STATE_PANEL:
			state = STATE_PICK
			return true
	return false


func clip_done() -> StringName:
	match state:
		STATE_WINDOW_PUSH:
			state = STATE_PICK
		STATE_REACTION:
			state = STATE_LAUNCH
		STATE_LAUNCH:
			state = STATE_DONE
	return state


func next_state(input_action: StringName) -> StringName:
	if input_action in [&"confirm", &"press_any", &"interact"]:
		confirm()
	elif input_action in [&"back", &"cancel"]:
		back()
	elif input_action in [&"clip_done", &"finished"]:
		clip_done()
	elif input_action in [&"toggle_difficulty", &"move_left", &"move_right"]:
		if state == STATE_PANEL:
			toggle_difficulty()
		elif state == STATE_PICK:
			toggle_hero()
	elif input_action in [&"move_up", &"move_down"]:
		if state == STATE_MENU:
			toggle_menu()
	return state


func toggle_menu() -> void:
	menu_cursor = MENU_QUIT if menu_cursor == MENU_NEW_GAME else MENU_NEW_GAME


func move_menu(delta: int) -> void:
	if delta != 0:
		toggle_menu()


func select_menu_index(index: int) -> bool:
	if index == MENU_NEW_GAME or index == MENU_QUIT:
		menu_cursor = index
		return true
	return false


func can_pick_hero(target_hero: StringName) -> bool:
	return target_hero == HERO_RYDAN


func select_hero(target_hero: StringName) -> bool:
	hero = target_hero
	return can_pick_hero(target_hero)


func toggle_hero() -> void:
	hero = HERO_BILQIS if hero == HERO_RYDAN else HERO_RYDAN


func toggle_difficulty() -> void:
	difficulty = DIFF_HARD if difficulty == DIFF_NORMAL else DIFF_NORMAL


func set_difficulty(target_diff: StringName) -> void:
	if target_diff == DIFF_NORMAL or target_diff == DIFF_HARD:
		difficulty = target_diff
