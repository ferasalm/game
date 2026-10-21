class_name UiMotion
extends RefCounted
## UI tweens: they ignore Engine.time_scale (a battle hitstop must not slow a menu) and, bound to a node whose
## process mode is ALWAYS (every UiScreen), keep running while the tree is paused.

const QAM_KEYS: Array[StringName] = [&"c_qam_red", &"c_qam_amber", &"c_qam_green", &"c_qam_blue", &"c_qam_violet"]


## A tween bound to node that runs in real time.
static func tween(node: Node) -> Tween:
	var out: Tween = node.create_tween()
	out.set_ignore_time_scale(true)
	return out


## Fades a control in while it rises from slide pixels below its place (t_screen_in).
static func screen_in(control: Control) -> Tween:
	var style: UiStyleDef = Ui.style()
	var rest: float = control.position.y
	control.modulate.a = 0.0
	control.position.y = rest + style.size(&"s_slide")
	var out: Tween = tween(control).set_parallel(true)
	out.tween_property(control, "modulate:a", 1.0, style.time(&"t_screen_in"))
	out.tween_property(control, "position:y", rest, style.time(&"t_screen_in")).set_ease(Tween.EASE_OUT)
	return out


## Fades a control out (t_screen_out); the caller frees it when the tween ends.
static func screen_out(control: Control) -> Tween:
	var out: Tween = tween(control)
	out.tween_property(control, "modulate:a", 0.0, Ui.style().time(&"t_screen_out"))
	return out
