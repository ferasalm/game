class_name PromptGlyph
extends RefCounted
## Pure: the localization key of the button glyph for an action on keyboard or gamepad ("accept" -> Enter / A), and
## the fade of a world-space interaction prompt with distance. No nodes.


## "UI_GLYPH_KEY_ACCEPT" or "UI_GLYPH_PAD_ACCEPT".
static func key(action: StringName, gamepad: bool) -> String:
	return "UI_GLYPH_%s_%s" % ["PAD" if gamepad else "KEY", String(action).to_upper()]


## 1 up to `near`, 0 from `far` on, a straight line between (metres).
static func fade(distance: float, near: float, far: float) -> float:
	if far <= near:
		return 1.0 if distance <= near else 0.0
	return clampf((far - distance) / (far - near), 0.0, 1.0)
