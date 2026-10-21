extends Node
## Shows the qamariya shatter on a stand-in frame (a stripe pattern) so the glass can be judged without a fight.
## Run (not headless): "$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60 --quit-after 50
## -s res://tools/shot_scene.gd -- res://tools/shot_shatter.gd


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color(0.1, 0.12, 0.3)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var image := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	for y: int in 270:
		for x: int in 480:
			var stripe: float = 0.5 + 0.5 * sin(float(x + y) * 0.08)
			image.set_pixel(x, y, Color(0.9 * stripe, 0.6, 0.2 + 0.7 * (1.0 - stripe)))
	var shatter := BattleShatter.new()
	add_child(shatter)
	shatter.play(image, ContentDB.get_def("battle_juice", &"default") as JuiceDef)
