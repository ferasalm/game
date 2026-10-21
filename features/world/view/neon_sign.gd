class_name NeonSign
extends Node3D
## One neon sign: a dark board, a glowing frame and the text (Label3D in Reem Kufi, unshaded and boosted above
## 1 so it blooms). The text runs left to right as a line; each Arabic phrase inside it shapes joined and reads
## right to left. A sign with flicker dips now and then, like a failing tube.

const FONT: FontFile = preload("res://assets/fonts/reem_kufi.ttf")
const FONT_PX: int = 64
const FRAME: float = 0.07
const BOARD_DEPTH: float = 0.12
## The text may fill this much of the board's width.
const FIT: float = 0.88

var label: Label3D
var spec: SignSpec

var _time: float = 0.0
var _frame_mat: StandardMaterial3D


func _init(sign_spec: SignSpec, palette: PaletteDef) -> void:
	spec = sign_spec
	position = sign_spec.pos
	rotation_degrees.y = sign_spec.yaw
	var board_color: Color = palette.colors["k"]
	_add_box(Vector3(0.0, 0.0, 0.0), Vector3(spec.board.x, spec.board.y, BOARD_DEPTH), _flat(board_color))
	_frame_mat = _glow_material()
	var hx: float = spec.board.x / 2.0
	var hy: float = spec.board.y / 2.0
	var z: float = BOARD_DEPTH / 2.0
	_add_box(Vector3(0.0, hy, z), Vector3(spec.board.x + FRAME, FRAME, FRAME), _frame_mat)
	_add_box(Vector3(0.0, -hy, z), Vector3(spec.board.x + FRAME, FRAME, FRAME), _frame_mat)
	_add_box(Vector3(hx, 0.0, z), Vector3(FRAME, spec.board.y, FRAME), _frame_mat)
	_add_box(Vector3(-hx, 0.0, z), Vector3(FRAME, spec.board.y, FRAME), _frame_mat)
	label = Label3D.new()
	label.font = FONT
	label.font_size = FONT_PX
	label.pixel_size = spec.size / FONT_PX
	label.shaded = false
	label.double_sided = false
	label.text_direction = TextServer.DIRECTION_LTR
	label.modulate = _hot(spec.text_energy)
	label.outline_size = 0
	label.position = Vector3(0.0, 0.0, z + 0.02)
	add_child(label)


func _ready() -> void:
	label.text = tr(spec.key)
	var width_px: float = FONT.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX).x
	var fit: float = spec.board.x * FIT / maxf(width_px, 1.0)
	label.pixel_size = minf(spec.size / FONT_PX, fit)


func _process(delta: float) -> void:
	if spec.flicker <= 0.0:
		return
	_time += delta
	var phase: float = LightPick.phase_of(spec.pos)
	var dip: float = LightPick.flicker(spec.flicker, 9.0, phase, _time)
	if fmod(_time + phase, 7.0) < 0.25:
		dip *= 0.25
	label.modulate = _hot(spec.text_energy * dip)
	_frame_mat.albedo_color = _hot(spec.energy * dip)


func _hot(energy: float) -> Color:
	var c: Color = spec.color
	return Color(c.r * energy, c.g * energy, c.b * energy, 1.0)


func _glow_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = _hot(spec.energy)
	return mat


func _flat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return mat


func _add_box(at: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
