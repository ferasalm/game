class_name RoofOpening
extends RefCounted
## purpose: The prison-roof opening beat (docs/briefs/neon-roof.md item 2): the hero waits hidden, the hatch bursts
## (the camera shakes, a white flash), he hops out onto the spawn and lands; ticked by RoofScene so tests can step it.

var landed: bool = false

var _hero: IsoActor
var _world: Node2D
var _camera: Camera2D
var _spawn: Vector2
var _rules: NeonRoofRulesDef
var _wait: float
var _hop: float = -1.0
var _shake: float = 0.0


func _init(hero: IsoActor, world: Node2D, camera: Camera2D, spawn: Vector2, rules: NeonRoofRulesDef) -> void:
	_hero = hero
	_world = world
	_camera = camera
	_spawn = spawn
	_rules = rules
	_wait = rules.burst_delay
	_hero.visible = false


## Advances the beat; returns &"burst" on the frame the hatch bursts, &"landed" on the frame he lands, else &"".
func tick(delta: float) -> StringName:
	if landed:
		return &""
	if _hop < 0.0:
		_wait -= delta
		if _wait > 0.0:
			return &""
		_hop = 0.0
		_hero.visible = true
		_hero.play(&"run")
		_hero.position = _spawn - Vector2(0.0, _rules.hop_height)
		RoofBurst.flash(_world, _spawn, _rules.flash_time)
		_shake = _rules.burst_shake_time
		return &"burst"
	_hop += delta
	_shake_step(delta)
	var t: float = minf(_hop / maxf(_rules.hop_seconds, 0.001), 1.0)
	_hero.position = _spawn - Vector2(0.0, _rules.hop_height * (1.0 - t * t))
	if t < 1.0 or _shake > 0.0:
		return &""
	landed = true
	_hero.play(&"idle")
	return &"landed"


func _shake_step(delta: float) -> void:
	if _shake <= 0.0:
		return
	_shake -= delta
	var amount: float = _rules.burst_shake_intensity if _shake > 0.0 else 0.0
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amount
