class_name VfxPlayer
extends Node3D
## Paints a VfxDef: turns each layer into pooled VfxSprites around the actor and the target(s) and moves them
## every frame (no tweens, no allocation once the pool is warm). Keep this node at the world origin.

var _rng := RandomNumberGenerator.new()
var _free: Array[VfxSprite] = []
var _active: Array[VfxSprite] = []
var _total: int = 0


func _init() -> void:
	_rng.seed = 5
	VfxTextures.warm()


## Plays the effect of this def: `actor` and `targets` are the CharacterVisuals involved (targets may be empty).
func play(def: VfxDef, actor: CharacterVisual, targets: Array[CharacterVisual]) -> void:
	if actor == null or def == null:
		return
	var focus: CharacterVisual = targets[0] if not targets.is_empty() else actor
	var dir: float = signf(focus.global_position.x - actor.global_position.x)
	dir = 1.0 if dir == 0.0 else dir
	for layer: VfxLayer in def.layers:
		if layer.per_target() and not targets.is_empty():
			var previous: CharacterVisual = actor
			for i: int in targets.size():
				_spawn(layer, actor, previous if layer.chain else actor, targets[i], dir, i)
				previous = targets[i]
		else:
			_spawn(layer, actor, actor, focus, dir, 0)


## Draws one tiny sprite so the effect shader is ready before the first real effect.
func warm_up() -> void:
	var layer := VfxLayer.new()
	layer.time = 0.1
	layer.size = Vector2(0.01, 0.01)
	layer.size_end = layer.size
	layer.color = Color.BLACK
	var sprite: VfxSprite = _acquire()
	sprite.launch(&"glow", layer, 0.0, Vector3.ZERO, Vector3.ZERO, 1.0)
	_active.append(sprite)


func active_count() -> int:
	return _active.size()


func pool_size() -> int:
	return _total


func clear() -> void:
	while not _active.is_empty():
		_release(_active.size() - 1)


func _process(delta: float) -> void:
	var i: int = _active.size() - 1
	while i >= 0:
		if not _active[i].tick(delta):
			_release(i)
		i -= 1


## `source` is where a chained layer starts from (the previous target; the actor otherwise).
func _spawn(layer: VfxLayer, actor: CharacterVisual, source: CharacterVisual, target: CharacterVisual, dir: float,
		index: int) -> void:
	for n: int in layer.count:
		var sprite: VfxSprite = _acquire()
		var start: Vector3 = _point(layer.from, actor, source, target, dir) + _flat(layer.offset, dir)
		if layer.chain and source != actor:
			start = _middle(source) + _flat(layer.offset, dir)
		start += _scatter(layer)
		var finish: Vector3 = start + _flat(layer.move, dir)
		var angle: float = 0.0
		if layer.radial:
			angle = TAU * (float(n) + _rng.randf()) / float(layer.count)
			finish = start + Vector3(cos(angle), sin(angle), 0.0) * layer.move.x
		if layer.to != &"":
			finish = _point(layer.to, actor, source, target, dir) + _flat(layer.to_offset, dir)
		var delay: float = layer.delay + layer.stagger * float(n + index)
		var straight: bool = layer.span or layer.aim
		if layer.span:
			sprite.launch(layer.tex, layer, delay, (start + finish) * 0.5, (start + finish) * 0.5, 1.0)
		else:
			sprite.launch(layer.tex, layer, delay, start, finish, 1.0 if straight else dir)
		_orient(sprite, layer, start, finish, angle, dir)
		_active.append(sprite)


func _orient(sprite: VfxSprite, layer: VfxLayer, start: Vector3, finish: Vector3, angle: float, dir: float) -> void:
	var roll: float = deg_to_rad(layer.rot) * dir + deg_to_rad(_rng.randf_range(-layer.roll, layer.roll))
	var spin: float = deg_to_rad(layer.spin) * dir
	var along := Vector2(finish.x - start.x, finish.y - start.y)
	if layer.span:
		sprite.set_sizes(Vector2(along.length(), layer.size.y), Vector2(along.length(), layer.size_end.y))
		roll = along.angle()
		spin = 0.0
	elif layer.aim:
		roll = angle if layer.radial else along.angle()
		spin = 0.0
	sprite.set_roll(roll, roll + spin)


## World point of a named anchor: the middle of a unit, its feet or head, its front hand, or halfway.
func _point(anchor: StringName, actor: CharacterVisual, source: CharacterVisual, target: CharacterVisual,
		dir: float) -> Vector3:
	match anchor:
		&"actor":
			return _middle(source)
		&"hand":
			return actor.global_position + Vector3(dir * 0.55, actor.height() * 0.55, 0.0)
		&"feet":
			return target.global_position + Vector3(0.0, 0.08, 0.0)
		&"head":
			return target.global_position + Vector3(0.0, target.height() + 0.1, 0.0)
		&"mid":
			return (_middle(source) + _middle(target)) * 0.5
	return _middle(target)


func _middle(unit: CharacterVisual) -> Vector3:
	return unit.global_position + Vector3(0.0, unit.height() * 0.5, 0.0)


func _flat(offset: Vector2, dir: float) -> Vector3:
	return Vector3(offset.x * dir, offset.y, 0.0)


func _scatter(layer: VfxLayer) -> Vector3:
	if layer.spread <= 0.0:
		return Vector3.ZERO
	return Vector3(_rng.randf_range(-layer.spread, layer.spread), _rng.randf_range(-layer.spread, layer.spread) * 0.6, 0.0)


func _acquire() -> VfxSprite:
	var sprite: VfxSprite = _free.pop_back() if not _free.is_empty() else null
	if sprite == null:
		sprite = VfxSprite.new()
		add_child(sprite)
		_total += 1
	return sprite


func _release(index: int) -> void:
	var sprite: VfxSprite = _active[index]
	sprite.visible = false
	_active.remove_at(index)
	_free.append(sprite)
