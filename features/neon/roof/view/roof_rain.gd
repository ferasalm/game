class_name RoofRain
extends ColorRect
## purpose: scrolling rain overlay placed over the exploration plate.


func setup(room_size: Vector2) -> void:
	size = room_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: Shader = load("res://features/neon/roof/view/roof_rain.gdshader") as Shader
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		material = sm
