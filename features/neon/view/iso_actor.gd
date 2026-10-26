class_name IsoActor
extends Node2D
## A character on an iso plate (docs/design/first-playable.md section 2): plays one baked NeonSpriteSetDef state in one
## of 8 facings, the node's position being the feet (y-sort by it). Signals the attack's impact frame and the end of a
## one-shot state; a held one-shot (hurt, ko) stays on its last frame. freeze() is the hit pause.

signal impact(state: StringName)
signal finished(state: StringName)

var sprite_set: NeonSpriteSetDef = null
var state: StringName = &"idle"
var facing: int = IsoDir.TOWARD_CAMERA
var _sprite: Sprite2D
var _data: NeonSpriteState = null
var _time: float = 0.0
var _frame: int = 0
var _frozen: float = 0.0
var _done: bool = false
var _textures: Dictionary[String, Texture2D] = {}


func _init() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)


## Uses the sprite set `set_id` (content/neon/sprites.json) and starts its idle.
func setup(set_id: StringName) -> void:
	sprite_set = ContentDB.get_def("neon_sprite_set", set_id) as NeonSpriteSetDef
	if sprite_set == null:
		push_error("IsoActor: no neon_sprite_set '%s'" % set_id)
		return
	_sprite.scale = Vector2.ONE * sprite_set.scale
	play(&"idle", true)


func play(new_state: StringName, restart: bool = false) -> void:
	if sprite_set == null or (new_state == state and not restart and not _done):
		return
	state = new_state
	_data = sprite_set.get_state(new_state)
	_time = 0.0
	_frame = 0
	_done = false
	_sprite.texture = _texture(_data.sheet)
	_sprite.hframes = _data.frames
	_sprite.vframes = IsoDir.COUNT
	_sprite.offset = -_data.pivot
	_show()


## Turns toward a screen direction (no change for a zero vector).
func face(direction: Vector2) -> void:
	facing = IsoDir.row(direction, facing)
	_show()


func freeze(seconds: float) -> void:
	_frozen = maxf(_frozen, seconds)


func is_playing_once() -> bool:
	return _data != null and not _data.loop and not _done


## The visual height in pixels (for labels and bars above the head).
func height() -> float:
	return 0.0 if _data == null else _data.pivot.y * sprite_set.scale


func _process(delta: float) -> void:
	if _data == null or _done:
		return
	if _frozen > 0.0:
		_frozen -= delta
		return
	_time += delta
	var next: int = int(_time * _data.fps)
	if _data.loop:
		next = next % _data.frames
	elif next >= _data.frames:
		_frame = _data.frames - 1
		_done = true
		_show()
		finished.emit(state)
		return
	if next != _frame:
		if _frame < _data.impact and next >= _data.impact:
			impact.emit(state)
		_frame = next
		_show()


func _show() -> void:
	if _data != null:
		_sprite.frame = facing * _data.frames + clampi(_frame, 0, _data.frames - 1)


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]
