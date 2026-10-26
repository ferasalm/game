class_name HologramStage
extends Control
## purpose: 800x760 menu hologram: the hero's Neon idle sprite (or portrait) with leader lines to the slot boxes.

const SIZE: Vector2 = Vector2(800.0, 760.0)
const ANCHORS_ID: StringName = &"default"

var _sprite: TextureRect
var _anchors: Hologram2dDef
var _lines: Dictionary[StringName, Line2D] = {}
var _box_anchors: Dictionary[StringName, Dictionary] = {}
var _active_slot: StringName = &"blade"


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchors = ContentDB.get_def("hologram_2d", ANCHORS_ID) as Hologram2dDef
	_sprite = TextureRect.new()
	_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)


func _process(_delta: float) -> void:
	_update_leader_lines()


func set_hero(hero: StringName) -> void:
	if _sprite != null:
		_sprite.texture = HologramSprite.texture_for(hero)


func set_active_slot(slot_name: StringName) -> void:
	_active_slot = slot_name
	_update_line_styles()


func register_box(part_name: StringName, box: Control, anchor_name: StringName) -> void:
	var style: UiStyleDef = Ui.style()
	var line := Line2D.new()
	line.width = float(style.size(&"s_frame_line"))
	line.default_color = style.colour(&"c_cyan")
	line.top_level = true
	add_child(line)
	_lines[part_name] = line
	_box_anchors[part_name] = {"box": box, "anchor": anchor_name}


## The picture now shown (an AtlasTexture for a Neon sprite, the portrait texture otherwise).
func sprite_texture() -> Texture2D:
	return _sprite.texture if _sprite != null else null


func visual() -> CharacterVisual:
	return null


func hologram_material() -> ShaderMaterial:
	return null


func disc() -> MeshInstance3D:
	return null


func model_meshes() -> Array[MeshInstance3D]:
	return []


func sub_viewport() -> SubViewport:
	return null


func lines() -> Dictionary[StringName, Line2D]:
	return _lines


func _update_leader_lines() -> void:
	if _box_anchors.is_empty():
		return
	for part_name: StringName in _box_anchors:
		var entry: Dictionary = _box_anchors[part_name]
		var box: Control = entry["box"] as Control
		var line: Line2D = _lines.get(part_name)
		if line == null:
			continue
		if box == null or not box.is_visible_in_tree():
			line.visible = false
			continue
		line.visible = true
		var is_left: bool = box.global_position.x < 800.0
		var box_x: float = box.global_position.x + (box.size.x if is_left else 0.0)
		var box_edge := Vector2(box_x, box.global_position.y + box.size.y * 0.5)
		var body_screen: Vector2 = _anchor_pos(entry["anchor"] as StringName)
		line.points = PackedVector2Array([box_edge, body_screen])
	_update_line_styles()


func _anchor_pos(anchor_name: StringName) -> Vector2:
	var fraction: Vector2 = _anchors.anchor(anchor_name) if _anchors != null else Vector2(0.5, 0.5)
	return global_position + size * fraction


func _update_line_styles() -> void:
	var style: UiStyleDef = Ui.style()
	var w_active: float = float(style.size(&"s_sweep_h"))
	var w_norm: float = float(style.size(&"s_frame_line"))
	for part_name: StringName in _lines:
		var line: Line2D = _lines[part_name]
		var is_act: bool = (part_name == _active_slot)
		line.default_color = style.colour(&"c_brass" if is_act else &"c_cyan")
		line.width = w_active if is_act else w_norm
		line.z_index = 1 if is_act else 0
