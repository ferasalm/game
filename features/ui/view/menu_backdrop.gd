class_name MenuBackdrop
extends Control
## Full-screen painted menu backdrop with blur fallback.
## Displays a painted webp or falls back to blurred viewport / deep glass.

const BLUR_SHADER: Shader = preload("res://features/ui/view/menu_blur.gdshader")

var backdrop_id: StringName = &""


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Sets up the backdrop texture by id, or applies the fallback if missing.
func setup(id: StringName, fallback_frame: Image = null) -> MenuBackdrop:
	backdrop_id = id
	var def := ContentDB.get_def("backdrop", id) as BackdropDef
	var tex: Texture2D = _load_texture(def)
	if tex != null:
		_build_painted(tex, def.dim if def != null else 0.35)
	else:
		_build_fallback(fallback_frame)
	return self


func _load_texture(def: BackdropDef) -> Texture2D:
	if def == null:
		return null
	var path: String = def.path
	if not path.begins_with("res://") and not path.begins_with("user://"):
		path = "res://" + path
	if not FileAccess.file_exists(path):
		return null
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var img := Image.new()
	if img.load_webp_from_buffer(bytes) != OK:
		return null
	return ImageTexture.create_from_image(img)


func _build_painted(tex: Texture2D, dim: float) -> void:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	var dim_rect := ColorRect.new()
	dim_rect.color = Color(0.0, 0.0, 0.0, dim)
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim_rect)


func _build_fallback(fallback_frame: Image) -> void:
	var frame: Image = fallback_frame
	if frame == null and DisplayServer.get_name() != "headless" and is_inside_tree() and get_viewport() != null and get_viewport().get_texture() != null:
		frame = get_viewport().get_texture().get_image()
	if frame != null and not frame.is_empty():
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(frame)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = BLUR_SHADER
		mat.set_shader_parameter(&"radius", float(Ui.style().size(&"s_backdrop_blur")))
		tr.material = mat
		add_child(tr)
		var scrim := ColorRect.new()
		scrim.color = Ui.style().colour(&"c_scrim")
		scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(scrim)
	else:
		var fill := ColorRect.new()
		fill.color = Ui.style().colour(&"c_glass_deep")
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
