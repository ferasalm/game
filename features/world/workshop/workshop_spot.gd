class_name WorkshopSpot
extends Node3D
## The workshop bench: its sprite, and a floating prompt that shows while the player is within the interact
## radius. Pressing interact there emits `opened`.

## The player pressed interact next to the bench.
signal opened

## The floating "E: workshop" label (public so tests can read whether it shows).
var prompt: Label3D

var _rules: ExploreRulesDef
var _player: Player
var _active: bool = true


func _init(rules: ExploreRulesDef, player: Player) -> void:
	_rules = rules
	_player = player
	var bench := CharacterVisual.new()
	bench.set_sprite(&"workshop_bench")
	bench.set_prop(true)
	add_child(bench)
	prompt = Label3D.new()
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.no_depth_test = true
	prompt.pixel_size = rules.prompt_pixel_size
	prompt.font_size = rules.prompt_font_size
	prompt.position.y = bench.height() + rules.prompt_height
	prompt.visible = false
	add_child(prompt)


func _ready() -> void:
	prompt.text = tr("WORLD_PROMPT_WORKSHOP")


## Off: the prompt hides and interact does nothing. On: works again.
func set_active(on: bool) -> void:
	_active = on
	prompt.visible = on and _is_near()


func _physics_process(_delta: float) -> void:
	prompt.visible = _active and _is_near()


func _unhandled_input(event: InputEvent) -> void:
	if _active and _is_near() and event.is_action_pressed("interact"):
		opened.emit()
		get_viewport().set_input_as_handled()


func _is_near() -> bool:
	var offset: Vector3 = _player.position - position
	offset.y = 0.0
	return offset.length() <= _rules.interact_radius
