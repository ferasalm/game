class_name RoofFloodlight
extends Polygon2D
## purpose: animated floodlight cone fading from additive light-blue glow to dark multiply with flickers.

var _mat: CanvasItemMaterial


func _ready() -> void:
	_mat = CanvasItemMaterial.new()
	_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _mat
	color = Color(0.55, 0.8, 1.0, 0.35)


func setup_shape(pts: PackedVector2Array) -> void:
	polygon = pts


func kill_light(duration: float = 0.6) -> void:
	var tw: Tween = create_tween()
	# Flicker 1
	tw.tween_property(self, "color", Color(0.55, 0.8, 1.0, 0.05), 0.1)
	tw.tween_property(self, "color", Color(0.55, 0.8, 1.0, 0.35), 0.08)
	# Flicker 2
	tw.tween_property(self, "color", Color(0.55, 0.8, 1.0, 0.03), 0.1)
	tw.tween_property(self, "color", Color(0.55, 0.8, 1.0, 0.2), 0.07)
	# Switch to multiply dark overlay and fade over rest of duration
	var rest_time: float = maxf(0.1, duration - 0.35)
	tw.tween_callback(func() -> void:
		_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		color = Color(0.85, 0.85, 0.9, 1.0)
	)
	tw.tween_property(self, "color", Color(0.15, 0.15, 0.25, 1.0), rest_time)
