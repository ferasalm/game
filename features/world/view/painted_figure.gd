class_name PaintedFigure
extends MeshInstance3D
## Look spike: a static painted billboard of Zayd (assets/textures/painted/figures/zayd.webp, cut from the owner's
## Flow picture by tools/art/figure_cut.py) with the shared painted light and an alpha-edge ink line. It stands in
## for the host's pixel sprite (which it hides) and mirrors when the host walks the other way. No rig: the puppet
## builder replaces this.

const SHADER: Shader = preload("res://features/world/view/shaders/painted_figure.gdshader")
const FIGURE_PATH: String = "res://assets/textures/painted/figures/zayd.webp"
const TURN_SPEED: float = 0.05  ## metres of sideways travel before the figure turns

var material: ShaderMaterial
var _last_x: float = 0.0
var _facing: float = 1.0


## Hides the CharacterVisual children of host and puts a painted figure in their place (false when the picture is
## missing: the sprite then stays).
static func replace_sprite(host: Node3D, paint: PaintDef) -> bool:
	var figure := PaintedFigure.new()
	if not figure.setup(paint):
		figure.free()
		return false
	for child: Node in host.get_children():
		if child is CharacterVisual:
			(child as CharacterVisual).visible = false
	host.add_child(figure)
	return true


func setup(paint: PaintDef) -> bool:
	if not FileAccess.file_exists(FIGURE_PATH):
		return false
	var image := Image.new()
	if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(FIGURE_PATH)) != OK:
		return false
	image.generate_mipmaps()
	var quad := QuadMesh.new()
	var aspect: float = float(image.get_width()) / float(image.get_height())
	quad.size = Vector2(paint.figure_height * aspect, paint.figure_height)
	quad.center_offset = Vector3(0.0, paint.figure_height * 0.5, 0.0)
	mesh = quad
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"albedo_tex", ImageTexture.create_from_image(image))
	material.set_shader_parameter(&"ink_color", paint.outline_color)
	paint.apply_light(material, true)
	material.set_shader_parameter(&"flip", -_facing)
	material_override = material
	return true


func _ready() -> void:
	_last_x = global_position.x


func _process(_delta: float) -> void:
	var x: float = global_position.x
	if absf(x - _last_x) > TURN_SPEED:
		_facing = signf(x - _last_x)
		_last_x = x
		material.set_shader_parameter(&"flip", -_facing)  # the picture faces left; game art faces right
