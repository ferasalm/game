class_name UiTransition
extends RefCounted
## The qamariya screen wipe: five stained-glass shards (red, amber, green, blue, violet) drop over the screen one
## after another, cover it, then lift away. t_transition_sweep is the whole thing. at_cover runs when the screen is
## fully covered (swap the scene there). Used for screen changes and the battle warp.


## Runs the wipe on `on` (a full-screen Control or CanvasLayer root) and returns its tween.
static func sweep(on: Control, at_cover: Callable = Callable()) -> Tween:
	var style: UiStyleDef = Ui.style()
	var count: int = UiMotion.QAM_KEYS.size()
	var half: float = style.time(&"t_transition_sweep") * 0.5
	var stagger: float = half / float(count + 1)
	var drop: float = half - stagger * float(count - 1)
	var shards: Array[ColorRect] = []
	var out: Tween = UiMotion.tween(on).set_parallel(true)
	for i: int in count:
		var shard := ColorRect.new()
		shard.color = style.colour(UiMotion.QAM_KEYS[i])
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shard.anchor_left = float(i) / float(count)
		shard.anchor_right = float(i + 1) / float(count)
		shard.anchor_top = 0.0
		shard.anchor_bottom = 0.0
		on.add_child(shard)
		shards.append(shard)
		var delay: float = stagger * float(i)
		out.tween_property(shard, "anchor_bottom", 1.0, drop).set_delay(delay)
		out.tween_property(shard, "anchor_top", 1.0, drop).set_delay(half + delay)
	out.chain().tween_callback(_clear.bind(shards))
	if at_cover.is_valid():
		out.tween_callback(at_cover).set_delay(half)
	AudioDirector.play_ui(&"ui_sweep")
	return out


static func _clear(shards: Array[ColorRect]) -> void:
	for shard: ColorRect in shards:
		if is_instance_valid(shard):
			shard.queue_free()
