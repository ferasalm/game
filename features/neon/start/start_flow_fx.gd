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


static func push_blur(mat: ShaderMaterial, duration: float, tree_node: Node) -> void:
	if mat == null or tree_node == null:
		return
	var tw: Tween = tree_node.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("blur_amount", v), 0.0, 0.75, duration * 0.4)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("blur_amount", v), 0.75, 0.0, duration * 0.6)


static func blur_zoom(mat: ShaderMaterial, duration: float, tree_node: Node, on_mid: Callable) -> void:
	if tree_node == null:
		on_mid.call()
		return
	if mat == null:
		on_mid.call()
		return
	var tw: Tween = tree_node.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("blur_amount", v), 0.0, 0.8, duration * 0.5)
	tw.tween_callback(on_mid)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("blur_amount", v), 0.8, 0.0, duration * 0.5)


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
