class_name NeonSpriteSetDef
extends Def
## One character's baked iso sprites (content/neon/sprites.json, docs/design/first-playable.md section 2): per state
## a sheet whose rows are the 8 screen directions and whose columns are the frames, its feet pivot, speed and impact.

var model: StringName = &""
var scale: float = 1.0
var states: Dictionary[StringName, NeonSpriteState] = {}


func read(r: DefReader) -> void:
	id = r.id()
	model = r.id("model")
	scale = r.number("scale", 0.1, 4.0)
	for s: DefReader in r.objects("states"):
		var state := NeonSpriteState.new()
		state.read(s)
		states[state.state] = state


## The state's data, or the idle state's when this set has no such state (never null for a valid set).
func get_state(state: StringName) -> NeonSpriteState:
	return states.get(state, states.get(&"idle")) as NeonSpriteState


func references() -> Array[Array]:
	return []
