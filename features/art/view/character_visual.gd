class_name CharacterVisual
extends Node3D
## A pixel-art character standing in the 3D world: a billboard Sprite3D (feet on the node's origin) plus its
## small animations (walking bob, lunge, hit flash, knocked out). Built in code; numbers come from
## content/art/visual.json. The art faces right. Gameplay code only uses the public methods below.

const RULES_ID: StringName = &"default"
const FLASH_TINT: Color = Color(3.0, 1.6, 1.6)
const DOWN_TINT: Color = Color(0.6, 0.55, 0.65)

var _rules: VisualRulesDef
var _pivot: Node3D
var _sprite: Sprite3D
var _moving: bool = false
var _down: bool = false
var _bob_time: float = 0.0
var _height_px: int = 0
var _ppm: float = 1.0


func _init() -> void:
	_rules = ContentDB.get_def("visual_rules", RULES_ID) as VisualRulesDef
	if _rules == null:
		_rules = VisualRulesDef.new()
	_pivot = Node3D.new()
	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.shaded = true
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_pivot.add_child(_sprite)
	add_child(_pivot)
	set_process(false)


## Shows the sprite with this id (a magenta placeholder when the id or its palette is missing).
func set_sprite(sprite_id: StringName) -> void:
	var def := ContentDB.get_def("sprite", sprite_id) as SpriteDef
	_ppm = def.pixels_per_metre if def != null and def.pixels_per_metre > 0.0 else _rules.pixels_per_metre
	_sprite.pixel_size = 1.0 / _ppm
	var palette: PaletteDef = null
	if def != null:
		palette = ContentDB.get_def("palette", def.palette) as PaletteDef
	if def == null or palette == null:
		_apply(ImageTexture.create_from_image(
			PixelArt.placeholder(_rules.placeholder_width, _rules.placeholder_height)))
		return
	_apply(PixelArt.texture(def, palette))


## The art faces right: a negative x direction mirrors it.
func face(dir_x: float) -> void:
	if not is_zero_approx(dir_x):
		_sprite.flip_h = dir_x < 0.0


func set_moving(on: bool) -> void:
	_moving = on
	set_process(on)
	if not on:
		_pivot.position.y = 0.0


## A quick step toward a world point and back. Callers await it.
func lunge(toward: Vector3) -> void:
	if not is_inside_tree():
		return
	var start: Vector3 = global_position
	var flat: Vector3 = Vector3(toward.x - start.x, 0.0, toward.z - start.z)
	var step: Vector3 = flat.limit_length(_rules.lunge_distance)
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", start + step, _rules.lunge_time)
	tween.tween_property(self, "global_position", start, _rules.lunge_time)
	await tween.finished


## A brief bright hit flash.
func flash() -> void:
	if not is_inside_tree():
		return
	_sprite.modulate = FLASH_TINT
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", _rest_tint(), _rules.flash_time)


## Knocked out (squashed and dimmed) or back on their feet.
func set_down(down: bool) -> void:
	_down = down
	_sprite.modulate = _rest_tint()
	_sprite.scale = Vector3(1.0, _rules.down_squash if down else 1.0, 1.0)
	_sprite.position.y = _half_height() * _sprite.scale.y


## Sprite height in metres, for placing labels above a head.
func height() -> float:
	return float(_height_px) / _ppm


func _process(delta: float) -> void:
	_bob_time += delta * _rules.bob_speed
	_pivot.position.y = absf(sin(_bob_time)) * _rules.bob_height


func _apply(texture: ImageTexture) -> void:
	_sprite.texture = texture
	_height_px = texture.get_height()
	_sprite.position.y = _half_height() * _sprite.scale.y


func _half_height() -> float:
	return height() / 2.0


func _rest_tint() -> Color:
	if _down:
		return DOWN_TINT
	return Color.WHITE
