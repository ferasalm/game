class_name InteractSpot
extends Node3D
## Something the player can press interact next to: a floating prompt (a localization key) that shows while he is
## within the interact radius, and a virtual _interact() that runs on the key press. The workshop bench and the
## chests build on it.

## The floating "E: ..." label (public so tests can read whether it shows).
var prompt: Label3D

var _rules: ExploreRulesDef
var _player: Player
var _active: bool = true
var _prompt_key: String = ""


func _init(rules: ExploreRulesDef, player: Player, prompt_key: String, prompt_y: float) -> void:
	_rules = rules
	_player = player
	_prompt_key = prompt_key
	prompt = Label3D.new()
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.no_depth_test = true
	prompt.pixel_size = rules.prompt_pixel_size
	prompt.font_size = rules.prompt_font_size
	prompt.position.y = prompt_y
	prompt.visible = false
	add_child(prompt)


func _ready() -> void:
	prompt.text = tr(_prompt_key)


## Off: the prompt hides and interact does nothing. On: works again.
func set_active(on: bool) -> void:
	_active = on
	prompt.visible = on and _can_interact()


func _physics_process(_delta: float) -> void:
	prompt.visible = _active and _can_interact()


func _unhandled_input(event: InputEvent) -> void:
	if _active and _can_interact() and event.is_action_pressed("interact"):
		_interact()
		get_viewport().set_input_as_handled()


## Override: what pressing interact does.
func _interact() -> void:
	pass


## Override to add conditions (a chest that is already open offers nothing).
func _can_interact() -> bool:
	return _is_near()


func _is_near() -> bool:
	var offset: Vector3 = _player.position - position
	offset.y = 0.0
	return offset.length() <= _rules.interact_radius
