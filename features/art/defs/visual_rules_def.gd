class_name VisualRulesDef
extends Def
## Numbers for how a CharacterVisual looks and moves (art scale, walking bob, lunge, hit flash, knocked out).

var pixels_per_metre: float = 16.0
var bob_height: float = 0.0
var bob_speed: float = 0.0
var lunge_distance: float = 0.0
var lunge_time: float = 0.0
var flash_time: float = 0.0
var down_squash: float = 1.0
var placeholder_width: int = 16
var placeholder_height: int = 32


func read(r: DefReader) -> void:
	id = r.id()
	pixels_per_metre = r.number("pixels_per_metre", 1.0, 64.0)
	bob_height = r.number("bob_height", 0.0, 1.0)
	bob_speed = r.number("bob_speed", 0.0, 30.0)
	lunge_distance = r.number("lunge_distance", 0.0, 5.0)
	lunge_time = r.number("lunge_time", 0.01, 2.0)
	flash_time = r.number("flash_time", 0.01, 2.0)
	down_squash = r.number("down_squash", 0.1, 1.0)
	placeholder_width = r.integer("placeholder_width", 1, 128)
	placeholder_height = r.integer("placeholder_height", 1, 128)
