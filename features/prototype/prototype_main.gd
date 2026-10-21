class_name PrototypeMain
extends Node3D
## The playable prototype: the rooftop, the workshop (talk once, then the bench menu) and the patrol battle,
## wired through the other features' public signals. Children are built in code; a BattleStage lives only while
## a battle runs.

## A battle stage was just made, before start(); tests use it to switch on auto_play / instant.
signal stage_created(new_stage: BattleStage)

const ROOFTOP_SCENE: PackedScene = preload("res://features/world/rooftop/rooftop.tscn")
const WORKSHOP_DIALOGUE: StringName = &"workshop_first"
const WORKSHOP_FLAG: StringName = &"workshop_talk_done"
const START_LOADOUT: StringName = &"zayd_start"

var rooftop: Rooftop
var dialogue: DialogueBox
var menu: WorkshopMenu
## The running battle's stage, null while exploring.
var stage: BattleStage
var _encounter_id: StringName = &""
var _ambush: int = 0
var _battles: int = 0


func _ready() -> void:
	rooftop = ROOFTOP_SCENE.instantiate() as Rooftop
	add_child(rooftop)
	dialogue = DialogueBox.new()
	add_child(dialogue)
	menu = WorkshopMenu.new()
	add_child(menu)
	rooftop.workshop_opened.connect(_on_workshop_opened)
	rooftop.encounter_touched.connect(_on_encounter_touched)
	dialogue.finished.connect(_on_dialogue_finished)
	menu.closed.connect(_on_menu_closed)
	rooftop.play_intro()


func _on_workshop_opened() -> void:
	rooftop.set_exploring(false)
	if GameState.flags.get(WORKSHOP_FLAG, false):
		menu.open()
	else:
		dialogue.play(WORKSHOP_DIALOGUE)


func _on_dialogue_finished(dialogue_id: StringName) -> void:
	if dialogue_id != WORKSHOP_DIALOGUE:
		return
	GameState.flags[WORKSHOP_FLAG] = true
	menu.open()


func _on_menu_closed() -> void:
	rooftop.set_exploring(true)


func _on_encounter_touched(encounter_id: StringName, _from_behind: bool) -> void:
	_encounter_id = encounter_id
	_ambush = rooftop.last_touch_ambush()
	rooftop.set_exploring(false)
	EventBus.battle_started.emit(encounter_id)
	_start_battle()


func _start_battle() -> void:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB, _encounter_id)
	var start := ContentDB.get_def("loadout", START_LOADOUT) as LoadoutDef
	var pair: Array[StringName] = Loadout.current(GameState.equipment, start)
	_battles += 1
	var battle_seed: int = hash([_battles, Time.get_ticks_usec()])
	stage = BattleStage.new()
	add_child(stage)
	stage.ended.connect(_on_battle_ended)
	stage_created.emit(stage)
	stage.start(loader.make_sim(pair[0], pair[1], battle_seed, _ambush), rooftop.battle_anchor())


func _drop_stage() -> void:
	remove_child(stage)
	stage.queue_free()
	stage = null


func _on_battle_ended(result: StringName) -> void:
	_drop_stage()
	if result == &"retry":
		_start_battle()
		return
	EventBus.battle_ended.emit(_encounter_id, result == &"victory")
	rooftop.reset_patrol()
	rooftop.restore_camera()
	rooftop.set_exploring(true)
