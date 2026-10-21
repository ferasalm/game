class_name PrototypeMain
extends Node3D
## The playable prototype: the rooftop, the workshop (talk once, then the equipment screen), the patrol battle,
## the title overlay, area title card and loot banners, wired through the other features' public signals. Children are built in code; a BattleStage lives only while
## a battle runs.

## A battle stage was just made, before start(); tests use it to switch on auto_play / instant.
signal stage_created(new_stage: BattleStage)

const ROOFTOP_SCENE: PackedScene = preload("res://features/world/rooftop/rooftop.tscn")
const WORKSHOP_DIALOGUE: StringName = &"workshop_first"
const WORKSHOP_FLAG: StringName = &"workshop_talk_done"
const EXPLORE_MUSIC: StringName = &"night_rooftops"
const BATTLE_MUSIC: StringName = &"battle"
const BENCH_PLACE: StringName = &"workshop"
const AREA_CARD: Array[String] = ["AREA_SOUQ_NAME", "AREA_SOUQ_NAME_AR", "AREA_SUBTITLE"]

var rooftop: Rooftop
var dialogue: DialogueBox
var menu: EquipmentScreen
## The title over the opening sky (null once it is gone), and the banners for the area and for loot.
var title: TitleOverlay
var area_card: AreaTitleCard
var loot_popup: LootPopup
## The running battle's stage, null while exploring.
var stage: BattleStage
var _encounter_id: StringName = &""
var _ambush: int = 0
var _battles: int = 0


func _ready() -> void:
	_grant_start_gear()
	rooftop = ROOFTOP_SCENE.instantiate() as Rooftop
	add_child(rooftop)
	dialogue = DialogueBox.new()
	add_child(dialogue)
	menu = EquipmentScreen.new()
	add_child(menu)
	loot_popup = LootPopup.new()
	add_child(loot_popup)
	area_card = AreaTitleCard.new()
	add_child(area_card)
	rooftop.workshop_opened.connect(_on_workshop_opened)
	rooftop.encounter_touched.connect(_on_encounter_touched)
	rooftop.chest_opened.connect(_on_chest_opened)
	dialogue.finished.connect(_on_dialogue_finished)
	menu.closed.connect(_on_menu_closed)
	AudioDirector.play_music(EXPLORE_MUSIC)
	rooftop.play_intro()
	_show_title()


## The title holds the opening shot on the moon until a key is pressed; the area card follows the shot.
func _show_title() -> void:
	title = TitleOverlay.new()
	add_child(title)
	rooftop.camera_rig.hold_intro(true)
	title.dismissed.connect(rooftop.camera_rig.hold_intro.bind(false))
	rooftop.camera_rig.intro_finished.connect(title.dismiss)
	rooftop.camera_rig.intro_finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)


func _on_intro_finished() -> void:
	area_card.show_card(AREA_CARD[0], AREA_CARD[1], AREA_CARD[2])


func _on_workshop_opened() -> void:
	rooftop.set_exploring(false)
	_open_chests(BENCH_PLACE)  # the bench stock; chests already opened give nothing
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
	var party: Array[CombatantDef] = loader.party_from_equipment(GameState.equipment)
	_battles += 1
	AudioDirector.play_music(BATTLE_MUSIC)
	var battle_seed: int = hash([_battles, Time.get_ticks_usec()])
	stage = BattleStage.new()
	add_child(stage)
	stage.ended.connect(_on_battle_ended)
	stage_created.emit(stage)
	stage.start(loader.make_sim_for(party, battle_seed, _ambush), rooftop.battle_anchor())
	stage.hud.end_panel.set_loot(loader.encounter.loot)


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
	AudioDirector.play_music(EXPLORE_MUSIC)
	if result == &"victory":
		_grant((ContentDB.get_def("encounter", _encounter_id) as EncounterDef).loot)
	rooftop.reset_patrol()
	rooftop.restore_camera()
	rooftop.set_exploring(true)


## A new game owns each hero's starting gear (they wear it through the loadout fallback).
func _grant_start_gear() -> void:
	if not GameState.inventory.is_empty():
		return
	for loadout_id: StringName in ContentDB.ids("loadout"):
		Inventory.add_all(GameState.inventory, (ContentDB.get_def("loadout", loadout_id) as LoadoutDef).item_ids())


## Opens every chest of this place that is still closed.
func _open_chests(place: StringName) -> void:
	var chests: Array[ChestDef] = []
	for chest_id: StringName in ContentDB.ids("chest"):
		chests.append(ContentDB.get_def("chest", chest_id) as ChestDef)
	for chest: ChestDef in Chests.at_place(chests, place):
		var given: StringName = Chests.open(chest, GameState.inventory, GameState.flags)
		if given != &"":
			EventBus.item_obtained.emit(given)


## A chest on the map was opened: its ChestDef (same id) gives its item once.
func _on_chest_opened(chest_id: StringName) -> void:
	var chest := ContentDB.get_def("chest", chest_id) as ChestDef
	if chest == null:
		push_warning("PrototypeMain: no chest '%s' in content/items/chests.json" % chest_id)
		return
	var given: StringName = Chests.open(chest, GameState.inventory, GameState.flags)
	if given != &"":
		EventBus.item_obtained.emit(given)


## Adds guaranteed loot to the inventory and announces each new item.
func _grant(item_ids: Array[StringName]) -> void:
	for item_id: StringName in Inventory.add_all(GameState.inventory, item_ids):
		EventBus.item_obtained.emit(item_id)
