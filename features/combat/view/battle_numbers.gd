class_name BattleNumbers
extends RefCounted
## The pop-up text of a battle: damage and heal numbers that pop in with an overshoot, bounce up and fade (bigger
## for heavy hits, green for heals), and the BREAK! stamp over a unit whose cast was cut. Sizes, times and colours
## come from the BattleViewDef and the JuiceDef; this class only animates.


## A number or short text that pops at `at` (world), bounces and fades. `size_factor` > 1 for heavy hits.
static func pop(parent: Node3D, content: String, at: Vector3, size: int, color: Color, size_factor: float,
		view: BattleViewDef, juice: JuiceDef, jitter_x: float) -> Label3D:
	var label: Label3D = BattleLabels.floating(content, size, color, view)
	parent.add_child(label)
	var start: Vector3 = at + Vector3(jitter_x * juice.number_jitter, 0.0, 0.0)
	label.position = start
	label.scale = Vector3.ONE * 0.2
	var rise: Tween = label.create_tween()
	rise.tween_property(label, "position:y", start.y + juice.bounce_height * size_factor, juice.bounce_time * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rise.tween_property(label, "position:y", start.y + juice.bounce_height * size_factor * 0.55, juice.bounce_time * 0.5) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	rise.tween_property(label, "position:y", start.y + juice.bounce_height * size_factor + view.number_rise * 0.4,
		view.number_seconds * 0.5)
	var look: Tween = label.create_tween()
	look.tween_property(label, "scale", Vector3.ONE * size_factor * juice.pop_scale, juice.pop_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	look.tween_property(label, "scale", Vector3.ONE * size_factor, juice.pop_time).set_trans(Tween.TRANS_BACK)
	look.tween_interval(maxf(view.number_seconds * 0.45 - juice.pop_time * 2.0, 0.0))
	BattleLabels.fade_out(look, label, view.number_seconds * 0.4)
	return label


## BREAK! slams in big, shudders and fades.
static func stamp(parent: Node3D, content: String, at: Vector3, view: BattleViewDef, juice: JuiceDef) -> Label3D:
	var label: Label3D = BattleLabels.floating(content, juice.break_size, juice.break_color, view)
	parent.add_child(label)
	label.position = at
	label.scale = Vector3.ONE * juice.pop_scale * 2.0
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "scale", Vector3.ONE, juice.pop_time * 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i: int in 4:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		tween.tween_property(label, "position:x", at.x + side * 0.06, 0.03)
	tween.tween_property(label, "position:x", at.x, 0.03)
	tween.tween_interval(juice.break_seconds * 0.4)
	BattleLabels.fade_out(tween, label, juice.break_seconds * 0.4)
	return label
