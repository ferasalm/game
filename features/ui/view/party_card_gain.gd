class_name PartyCardGain
extends RefCounted
## purpose: Paints an item's gain as a green segment on a PartyCard stat bar, from now to now+gain capped at max.

const INSET: float = 2.0


## Adds a hidden gain segment over a stat bar; returns it.
static func overlay(bar: ProgressBar) -> ColorRect:
	var segment := ColorRect.new()
	segment.color = Ui.style().colour(&"c_good")
	segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	segment.anchor_top = 0.0
	segment.anchor_bottom = 1.0
	segment.offset_top = INSET
	segment.offset_bottom = -INSET
	segment.visible = false
	bar.add_child(segment)
	return segment


## Shows the gain from now to now+gain on the bar (capped at its maximum) when usable; hides it otherwise.
static func paint(segment: ColorRect, bar: ProgressBar, now: float, gain: int, usable: bool) -> void:
	if segment == null:
		return
	var top: float = maxf(bar.max_value, 1.0)
	var end: float = minf(now + float(gain), top)
	segment.visible = usable and gain > 0 and end > now
	if not segment.visible:
		return
	segment.anchor_left = now / top
	segment.anchor_right = end / top


static func hide(segment: ColorRect) -> void:
	if segment != null:
		segment.visible = false
