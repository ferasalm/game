class_name PrototypeMain
extends Node3D
## The playable prototype's composition root: builds the rooftop, the workshop dialogue and menu, the title overlay,
## area title card and loot banners, registers the rooftop with the Router and wires the features' public signals.
## Battles, rewards, saves and the flow state belong to the Router; this node only asks.

## A battle stage was just made, before start(); tests use it to switch on auto_play / instant (Router's signal).
signal stage_created(new_stage: BattleStage)

const ROOFTOP_SCENE: PackedScene = preload("res://features/world/rooftop/rooftop.tscn")
const WORKSHOP_DIALOGUE: StringName = &"workshop_first"
const WORKSHOP_FLAG: StringName = &"workshop_talk_done"
const BENCH_PLACE: StringName = &"workshop"
const AREA_CARD: Array[String] = ["AREA_SOUQ_NAME", "AREA_SOUQ_NAME_MUSNAD", "AREA_SUBTITLE"]

var rooftop: Rooftop
var dialogue: DialogueBox
var menu: EquipmentScreen
## The title over the opening sky (null once it is gone), and the banners for the area and for loot.
var title: TitleOverlay
var area_card: AreaTitleCard
var loot_popup: LootPopup
## The running battle's stage (the Router's), null while exploring.
var stage: BattleStage:
	get:
		return Router.stage
var _port: RooftopPort
var _battles: int = 0


func _ready() -> void:
	if GameState.party.is_empty():
		GameState.start_new()
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
	if rooftop.sabil != null:
		rooftop.sabil.opened.connect(_on_sabil_opened)
	for spot: TalkSpot in rooftop.talk_spots:
		spot.talked.connect(_on_npc_talked)
	dialogue.finished.connect(_on_dialogue_finished)
	menu.closed.connect(_on_menu_closed)
	GameState.area_id = rooftop.area_id
	_port = RooftopPort.new(rooftop, self)
	Router.register_area(_port)
	Router.stage_created.connect(_on_stage_created)
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	_begin()


func _exit_tree() -> void:
	Router.unregister_area(_port)
	Router.stage_created.disconnect(_on_stage_created)
	EventBus.battle_started.disconnect(_on_battle_started)
	EventBus.battle_ended.disconnect(_on_battle_ended)


## A fresh start plays the opening shot under the title; a new game or a load goes straight to the party's spot.
func _begin() -> void:
	var flow := ContentDB.get_def("flow_rules", &"default") as FlowRulesDef
	AudioDirector.play_music(flow.explore_music)
	if Router.take_skip_title():
		_port.place_party(GameState.save_point)
		Router.enter_exploring()
		return
	Router.enter_title()
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
	if Router.state != Router.STATE_TITLE:
		return  # a fight cut the opening short
	Router.enter_exploring()
	area_card.show_card(AREA_CARD[0], AREA_CARD[1], AREA_CARD[2])


func _on_workshop_opened() -> void:
	rooftop.set_exploring(false)
	Router.set_busy(true)
	RewardApplier.chests_at(BENCH_PLACE)  # the bench stock; chests already opened give nothing
	if GameState.flags.get(WORKSHOP_FLAG, false):
		menu.open()
	else:
		dialogue.play(WORKSHOP_DIALOGUE)


func _on_sabil_opened() -> void:
	if not GameState.flags.get(&"party_sabil_first_done", false):
		dialogue.play(&"party_sabil_first")


func _on_npc_talked(place_id: StringName) -> void:
	var talk_def := ContentDB.get_def("talk", place_id) as TalkDef
	if talk_def == null:
		return
	var dialogue_id: StringName = TalkPicker.pick(talk_def, GameState.flags)
	if not dialogue_id.is_empty():
		dialogue.play(dialogue_id)


func _on_battle_ended(_encounter_id: StringName, victory: bool) -> void:
	if victory:
		TalkPicker.record_battle_won(GameState.flags)
		if not GameState.flags.get(&"party_after_first_win_done", false):
			GameState.flags[&"party_after_first_win_done"] = true
			dialogue.play(&"party_after_first_win")


func _on_dialogue_finished(dialogue_id: StringName) -> void:
	if dialogue_id == WORKSHOP_DIALOGUE:
		GameState.flags[WORKSHOP_FLAG] = true
		menu.open()
		return
	if dialogue_id == &"party_sabil_first":
		GameState.flags[&"party_sabil_first_done"] = true
		if rooftop.sabil != null:
			rooftop.sabil.open_screen()
		return


func _on_menu_closed() -> void:
	Router.set_busy(false)
	rooftop.set_exploring(true)


func _on_encounter_touched(encounter_id: StringName, _from_behind: bool) -> void:
	_battles += 1
	var request := BattleRequest.new()
	request.encounter_id = encounter_id
	request.ambush = rooftop.last_touch_ambush()
	request.seed = hash([_battles, Time.get_ticks_usec()])
	request.party = GameState.party.duplicate()
	Router.start_battle(request)


func _on_stage_created(new_stage: BattleStage) -> void:
	stage_created.emit(new_stage)


func _on_battle_started(_encounter_id: StringName) -> void:
	area_card.dismiss()


## A chest on the map was opened: its ChestDef (same id) pays out once.
func _on_chest_opened(chest_id: StringName) -> void:
	RewardApplier.chest(chest_id)


## A new game owns each hero's starting gear (they wear it through the loadout fallback).
func _grant_start_gear() -> void:
	if not GameState.inventory.is_empty():
		return
	for loadout_id: StringName in ContentDB.ids("loadout"):
		Inventory.add_all(GameState.inventory, (ContentDB.get_def("loadout", loadout_id) as LoadoutDef).item_ids())
