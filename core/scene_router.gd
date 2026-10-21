extends Node
## Game flow owner (autoload Router): title -> area -> battle arena -> area, transitions, new game, load, can_save.
## Contract stub from the v0.3 plan: the foundation builder (P1a) fills in the bodies; screens and menus call only
## these methods and signals (docs/ARCHITECTURE.md section 9).

signal battle_finished(outcome: BattleOutcome)
signal flow_changed(state: StringName)

const STATE_TITLE: StringName = &"title"
const STATE_EXPLORING: StringName = &"exploring"
const STATE_BATTLE: StringName = &"battle"
const STATE_BUSY: StringName = &"busy"

var state: StringName = STATE_TITLE


func is_exploring() -> bool:
	return state == STATE_EXPLORING


func can_save() -> bool:
	return false


func has_save(_slot: int) -> bool:
	return false


func new_game() -> void:
	pass


func load_slot(_slot: int) -> String:
	return "not implemented"


func go_to_title() -> void:
	pass


func unstuck() -> void:
	pass


func quit_game() -> void:
	get_tree().quit()


func start_battle(_request: BattleRequest) -> void:
	pass
