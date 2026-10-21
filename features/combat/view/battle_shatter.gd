class_name BattleShatter
extends CanvasLayer
## The warp into a fight: the last frame of the area breaks into qamariya-glass shards that fall away and uncover the
## arena (battle_shatter.gdshader). Times and the dark crack colour come from the TransitionDef "shatter", the shard
## numbers from the JuiceDef. Without a frame (headless, or nothing was captured) there is nothing to break: play()
## returns at once and draws nothing.

const SHADER: Shader = preload("res://features/combat/view/battle_shatter.gdshader")
const TRANSITION_ID: StringName = &"shatter"
const GLASS_KEYS: Array[StringName] = [&"glass_0", &"glass_1", &"glass_2", &"glass_3", &"glass_4"]

var _rect: ColorRect
var _material: ShaderMaterial


## True when a frame can be shattered.
static func can_play(image: Image) -> bool:
	return image != null and not image.is_empty()


## Breaks `image` over the transition's seconds; callers await it. Frees itself when done.
func play(image: Image, juice: JuiceDef) -> void:
	if not can_play(image) or not is_inside_tree():
		queue_free()
		return
	var transition := ContentDB.get_def("transition", TRANSITION_ID) as TransitionDef
	layer = UiLayers.TRANSITION
	_material = _make_material(image, juice, transition)
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	add_child(_rect)
	var tween: Tween = UiMotion.tween(self)
	tween.tween_property(_material, "shader_parameter/progress", 1.0, transition.seconds if transition != null else 0.6)
	await tween.finished
	queue_free()


func _make_material(image: Image, juice: JuiceDef, transition: TransitionDef) -> ShaderMaterial:
	var out := ShaderMaterial.new()
	out.shader = SHADER
	out.set_shader_parameter(&"frame", ImageTexture.create_from_image(image))
	out.set_shader_parameter(&"progress", 0.0)
	var aspect: float = float(image.get_height()) / float(image.get_width())
	out.set_shader_parameter(&"cells", Vector2(juice.shatter_columns, juice.shatter_columns * aspect))
	out.set_shader_parameter(&"fall", juice.shatter_fall)
	out.set_shader_parameter(&"spread", juice.shatter_spread)
	out.set_shader_parameter(&"spin", juice.shatter_spin)
	out.set_shader_parameter(&"stagger", juice.shatter_stagger)
	out.set_shader_parameter(&"glass_amount", juice.shatter_glass)
	out.set_shader_parameter(&"crack", juice.shatter_crack)
	if transition != null:
		out.set_shader_parameter(&"crack_color", transition.color)
	for i: int in GLASS_KEYS.size():
		out.set_shader_parameter(GLASS_KEYS[i], Ui.style().colour(UiMotion.QAM_KEYS[i]))
	return out
