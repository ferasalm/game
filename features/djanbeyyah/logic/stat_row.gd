class_name StatRow
extends RefCounted
## One line of the workshop comparison: label key, value now (base) and value with the chosen pair.

const INT: StringName = &"int"
const PERCENT: StringName = &"percent"
const DECIMAL: StringName = &"decimal"

var label_key: String = ""
var kind: StringName = INT
## Weight has no good direction yet, so it is shown without good/bad colour.
var neutral: bool = false
var before: float = 0.0
var after: float = 0.0


func _init(label: String, value_kind: StringName, was: float, now: float, is_neutral: bool = false) -> void:
	label_key = label
	kind = value_kind
	before = was
	after = now
	neutral = is_neutral


## The value as shown to the player: whole number, whole percent, or one decimal.
func format(value: float) -> String:
	match kind:
		PERCENT:
			return "%d%%" % roundi(value)
		DECIMAL:
			return "%.1f" % value
	return "%d" % roundi(value)


## -1, 0 or 1: how the value changed (tiny float noise counts as no change).
func direction() -> int:
	if absf(after - before) < 0.0005:
		return 0
	return 1 if after > before else -1
