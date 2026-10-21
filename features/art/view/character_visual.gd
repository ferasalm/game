class_name CharacterVisual
extends Node3D
## A character standing in the 3D world (feet on the node's origin). This is the facade the game talks to:
## `play(state, facing)` with the states idle, walk, run, attack, cast, hurt, ko, victory, item; the anchors
## feet / hand / head; and the signal clip_event the battle view can wait on. What draws it is a VisualSource
## behind the facade (PixelSource today, PuppetSource later; the rules def picks). The root moves (lunge, dash,
## hurt push) are CharacterMotion's. Numbers come from content/art/visual.json. The art faces right.

## A one-shot clip reached a named frame: &"impact" (the hit lands) or &"end" (the clip is over).
signal clip_event(event: StringName)

const RULES_ID: StringName = &"default"
const STATES: Array[StringName] = [&"idle", &"walk", &"run", &"attack", &"cast", &"hurt", &"ko", &"victory", &"item"]
const ANCHORS: Array[StringName] = [&"feet", &"hand", &"head"]

## Squash multiplier, hop height and knocked-out squash, moved by the battle motions (tween targets).
var pulse: Vector2 = Vector2.ONE
var lift: float = 0.0
var down_scale: Vector2 = Vector2.ONE
## Everything that slides (lunge, knockback, shake) lives under `root`; `body` pivots at the feet.
var root: Node3D
var body: Node3D
## The pixel source's shader material (null for a puppet).
var material: ShaderMaterial
var fx: CharacterFx
var rules: VisualRulesDef
var motion: CharacterMotion
var source: VisualSource
var state: StringName = &"idle"
var _moving: bool = false
var _down: bool = false
var _prop: bool = false
var _faced: bool = false
var _facing: float = 1.0


func _init() -> void:
	rules = ContentDB.get_def("visual_rules", RULES_ID) as VisualRulesDef
	if rules == null:
		rules = VisualRulesDef.new()
	root = Node3D.new()
	body = Node3D.new()
	root.add_child(body)
	add_child(root)
	fx = CharacterFx.new()
	add_child(fx)
	fx.setup(rules)
	motion = CharacterMotion.new()
	motion.setup(self, rules)
	use_source(PuppetSource.new() if rules.puppet else PixelSource.new())


## Swaps what draws the character (before the first picture is set).
func use_source(new_source: VisualSource) -> void:
	source = new_source
	source.attach(self, rules)
	source.clip_event.connect(clip_event.emit)
	var pixel := source as PixelSource
	material = pixel.material if pixel != null else null


## Shows the picture with this content id (a magenta placeholder when the id or its palette is missing).
func set_sprite(sprite_id: StringName) -> void:
	source.set_sprite(sprite_id)


## The contract for what the character is doing. facing: its direction (x < 0 faces left; zero keeps the facing).
## idle/walk/run are looping poses, ko and victory hold, attack/cast/item/hurt are one-shot clips that announce
## clip_event(&"impact") and clip_event(&"end"). Moving again from ko stands the character back up.
func play(new_state: StringName, facing: Vector2 = Vector2.ZERO) -> void:
	if not STATES.has(new_state):
		push_warning("CharacterVisual.play: unknown state %s" % new_state)
		return
	face(facing.x)
	state = new_state
	if _down and new_state != &"ko":
		set_down(false, true)
	match new_state:
		&"idle", &"walk", &"run":
			set_moving(new_state != &"idle")
		&"ko":
			set_moving(false)
			set_down(true, true)
		&"hurt":
			hurt(-_facing * rules.hurt_shake)
			source.play_clip(new_state, _facing)
		_:
			source.play_clip(new_state, _facing)


## World position of a body spot: &"feet", &"hand" (forward, mid-height), &"head".
func anchor_position(which: StringName) -> Vector3:
	return global_position + root.position + source.anchor(which)


## The art faces right: a negative x direction mirrors it (with a quick squash when it really turns).
func face(dir_x: float) -> void:
	if is_zero_approx(dir_x):
		return
	var facing: float = 1.0 if dir_x > 0.0 else -1.0
	if facing != _facing and _faced and is_inside_tree():
		source.cue(&"turn")
	_faced = true
	_facing = facing
	source.set_flip(facing)
	fx.set_flip(facing)


func set_moving(on: bool) -> void:
	_moving = on


## Scenery drawn as a character (a bench): no breathing.
func set_prop(on: bool) -> void:
	_prop = on


## Dash at a world point and come back. Callers await it.
func lunge(toward: Vector3) -> void:
	await anticipate(toward)
	await dash(toward)
	await return_home()


func anticipate(toward: Vector3) -> void:
	source.cue(&"anticipate")
	await motion.anticipate(toward)


## Dashes to the target (afterimages) and returns once in contact.
func dash(toward: Vector3) -> void:
	source.cue(&"dash")
	await motion.dash(toward)
	source.cue(&"impact")


func return_home() -> void:
	await motion.return_home()


## A ranged or support move: crouch, rise and hold. Callers await it.
func cast_pose(hold: float) -> void:
	await source.cast_pose(hold)


## A brief bright hit flash.
func flash() -> void:
	source.cue(&"flash")


## Hit: flash, squash, shake and a slide away from the attacker (push_x < 0 = left).
func hurt(push_x: float) -> void:
	source.cue(&"hurt")
	motion.hurt(push_x)


func victory_hop() -> void:
	await source.hop()


## Knocked out (collapsed and drained of colour) or back on their feet. `animate` plays the fall or the rise.
func set_down(down: bool, animate: bool = false) -> void:
	_down = down
	source.set_down(down, animate and is_inside_tree())


func is_down() -> bool:
	return _down


## Sprite height in metres, for placing labels above a head.
func height() -> float:
	return source.height()


func width() -> float:
	return source.width()


func tint_down(share: float) -> void:
	source.tint_down(share)


func _process(delta: float) -> void:
	source.update(delta, _moving, _prop, _down, _facing)
