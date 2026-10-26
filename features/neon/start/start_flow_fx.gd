class_name StartFlowFX
extends RefCounted
## Transitions and effects for the start flow (crossfades, blurs, and cover sizing).


static func crossfade(overlay: TextureRect, tex: Texture2D, duration: float, tree_node: Node) -> void:
	if overlay == null or tex == null or tree_node == null:
		return
	overlay.texture = tex
	overlay.modulate.a = 1.0
	var tw: Tween = tree_node.create_tween()
	tw.tween_property(overlay, "modulate:a", 0.0, duration)


static func push_blur(overlay: ColorRect, duration: float, peak: float, tree_node: Node) -> void:
	var mat: ShaderMaterial = _start_blur(overlay, tree_node)
	if mat == null:
		_end_blur(overlay, mat)
		return
	var tw: Tween = tree_node.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("blur_amount", v), 0.0, peak, duration * 0.4)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("blur_amount", v), peak, 0.0, duration * 0.6)
	tw.tween_callback(func() -> void: _end_blur(overlay, mat))


static func blur_zoom(overlay: ColorRect, duration: float, peak: float, tree_node: Node, on_mid: Callable) -> void:
	var mat: ShaderMaterial = _start_blur(overlay, tree_node)
	if mat == null:
		_end_blur(overlay, mat)
		on_mid.call()
		return
	var tw: Tween = tree_node.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("blur_amount", v), 0.0, peak, duration * 0.5)
	tw.tween_callback(on_mid)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("blur_amount", v), peak, 0.0, duration * 0.5)
	tw.tween_callback(func() -> void: _end_blur(overlay, mat))


static func _start_blur(overlay: ColorRect, tree_node: Node) -> ShaderMaterial:
	if overlay == null or tree_node == null:
		return null
	overlay.visible = true
	var mat: ShaderMaterial = overlay.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("blur_amount", 0.0)
	return mat


static func _end_blur(overlay: ColorRect, mat: ShaderMaterial) -> void:
	if mat != null:
		mat.set_shader_parameter("blur_amount", 0.0)
	if overlay != null:
		overlay.visible = false


static func fit_cover(target: Control, vp: Vector2, aspect_ratio: float) -> void:
	if target == null:
		return
	var vp_ratio: float = vp.x / maxf(vp.y, 1.0)
	if vp_ratio > aspect_ratio:
		target.size = Vector2(vp.x, vp.x / aspect_ratio)
		target.position = Vector2(0.0, (vp.y - target.size.y) * 0.5)
	else:
		target.size = Vector2(vp.y * aspect_ratio, vp.y)
		target.position = Vector2((vp.x - target.size.x) * 0.5, 0.0)
