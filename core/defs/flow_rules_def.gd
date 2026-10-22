class_name FlowRulesDef
extends Def
## Numbers and ids of the game flow (content/prototype/flow.json): which arena battles use, the music of exploring
## and of fighting, how long the player must stand still for a spot to count as safe (the unstuck target), and where
## the debug labels sit.

var arena_id: StringName = &""
var explore_music: StringName = &""
var battle_music: StringName = &""
## Seconds standing still before the spot is remembered as safe; a new entry must be farther than still_radius
## from the previous one.
var safe_idle_seconds: float = 2.0
var safe_still_radius: float = 1.5
var debug_font_size: int = 28
var debug_fps_pos: Vector2 = Vector2.ZERO
var debug_name_pos: Vector2 = Vector2.ZERO
var save_slots: int = 3


func read(r: DefReader) -> void:
	id = r.id()
	arena_id = r.id("arena_id")
	explore_music = r.id("explore_music")
	battle_music = r.id("battle_music")
	safe_idle_seconds = r.number("safe_idle_seconds", 0.1, 60.0)
	safe_still_radius = r.number("safe_still_radius", 0.1, 20.0)
	debug_font_size = r.integer("debug_font_size", 8, 96)
	debug_fps_pos = _vec2(r, "debug_fps_pos")
	debug_name_pos = _vec2(r, "debug_name_pos")
	save_slots = r.integer("save_slots", 1, 99, 3, false)
	SaveService.max_slots = save_slots


func references() -> Array[Array]:
	return [["arena", arena_id], ["music", explore_music], ["music", battle_music]]


static func _vec2(r: DefReader, key: String) -> Vector2:
	var values: Array[float] = r.float_list(key, -10000.0, 10000.0)
	if values.size() != 2:
		r.problem(key, "needs two numbers [x, y]")
		return Vector2.ZERO
	return Vector2(values[0], values[1])
