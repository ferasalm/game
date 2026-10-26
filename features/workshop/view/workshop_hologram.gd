class_name WorkshopHologram
extends Control
## purpose: 760x620 menu hologram: the hero's Neon idle sprite (or portrait), or a 256px item icon.

const SIZE: Vector2 = Vector2(760.0, 620.0)
const HERO: StringName = &"zayd"

var _sprite: TextureRect
var _icon_rect: TextureRect


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite = TextureRect.new()
	_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.texture = HologramSprite.texture_for(HERO)
	add_child(_sprite)


## Shows the hero's idle sprite.
func show_jambiyah() -> void:
	if _sprite != null:
		_sprite.visible = true
	if _icon_rect != null:
		_icon_rect.visible = false


## Shows a 256px 2D item icon instead of the hero sprite.
func show_icon(tex: Texture2D) -> void:
	if _sprite != null:
		_sprite.visible = false
	if _icon_rect == null:
		_icon_rect = TextureRect.new()
		_icon_rect.custom_minimum_size = Vector2(256.0, 256.0)
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_rect.set_anchors_preset(Control.PRESET_CENTER)
		_icon_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_icon_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(_icon_rect)
	_icon_rect.texture = tex
	_icon_rect.visible = (tex != null)


## Switches the hero whose idle sprite the hologram shows.
func set_hero(hero: StringName) -> void:
	if _sprite != null:
		_sprite.texture = HologramSprite.texture_for(hero)


func sprite_texture() -> Texture2D:
	return _sprite.texture if _sprite != null else null
