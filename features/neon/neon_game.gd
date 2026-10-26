class_name NeonGame
extends Node
## purpose: The Neon Glitch first playable from launch to the exit card (docs/design/first-playable.md section 1): the
## start flow, the Roya cold open, the prison roof, its turn-based fight on the map, "To be continued", then the start.

signal stage_changed(stage: StringName)

@export var start_scene: PackedScene
@export var cold_open_scene: PackedScene
@export var roof_scene: PackedScene
## The exit card: its font, how long it holds before the start flow returns (any key returns sooner), its fades.
@export var end_font: Font
@export var end_font_size: int
@export var end_card_seconds: float
@export var end_fade_seconds: float

var stage: StringName = &""
## Chosen in the start flow; not applied to the fights yet (HANDOFF: Hard is a later step).
var difficulty: StringName = &"normal"

var _current: Node
var _roof: RoofScene
var _battle: MapBattle
var _card_left: float = 0.0


func _ready() -> void:
	show_start()


func show_start() -> void:
	var flow := _swap(start_scene) as StartFlow
	flow.done.connect(_on_start_done, CONNECT_ONE_SHOT)
	_set_stage(&"start")


func show_cold_open() -> void:
	var cold := _swap(cold_open_scene) as ColdOpen
	cold.done.connect(show_roof, CONNECT_ONE_SHOT)
	_set_stage(&"cold_open")


func show_roof() -> void:
	_roof = _swap(roof_scene) as RoofScene
	_roof.battle_requested.connect(_on_battle_requested)
	_roof.exited.connect(show_end_card, CONNECT_ONE_SHOT)
	_set_stage(&"roof")


func show_end_card() -> void:
	var card := CanvasLayer.new()
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(black)
	var label := Label.new()
	label.text = tr("NEON_END_TBC")
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", end_font)
	label.add_theme_font_size_override("font_size", end_font_size)
	black.add_child(label)
	_swap_node(card)
	black.modulate.a = 0.0
	create_tween().tween_property(black, "modulate:a", 1.0, end_fade_seconds)
	_card_left = end_card_seconds
	_set_stage(&"end")


func _process(delta: float) -> void:
	if stage != &"end":
		return
	_card_left -= delta
	if _card_left <= 0.0:
		show_start()


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event.is_pressed() and not event.is_echo()
	if stage == &"end" and pressed and _card_left < end_card_seconds - end_fade_seconds:
		show_start()


func _on_start_done(chosen: StringName) -> void:
	difficulty = chosen
	GameState.start_new()
	show_cold_open()


func _on_battle_requested(foes: Array[IsoActor], contact: Vector2, ambush: bool) -> void:
	_battle = MapBattle.new()
	add_child(_battle)
	_battle.ended.connect(_on_battle_ended, CONNECT_ONE_SHOT)
	_set_stage(&"battle")
	_battle.begin(_roof.world(), _roof.room(), _roof.hero(), foes, contact, ambush)


func _on_battle_ended(won: bool) -> void:
	_battle.queue_free()
	_battle = null
	if not won:
		show_start()
		return
	_roof.mark_won()
	_roof.set_exploring(true)
	_set_stage(&"roof")


func _swap(scene: PackedScene) -> Node:
	var node: Node = scene.instantiate()
	_swap_node(node)
	return node


func _swap_node(node: Node) -> void:
	if _battle != null:
		_battle.queue_free()
		_battle = null
	if _current != null:
		_current.queue_free()
	_roof = null
	_current = node
	add_child(node)


## The playtest capture's view of the game: stage, roof room and hero, and the fight if one is running.
func playtest_state() -> Dictionary:
	return NeonPlaytestState.collect(stage, _roof, _battle)


func _set_stage(new_stage: StringName) -> void:
	stage = new_stage
	stage_changed.emit(new_stage)
