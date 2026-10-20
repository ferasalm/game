class_name TimelineEvent
extends RefCounted
## One thing that happened in a battle, for the battle view and logs: what, who, a value (timeline position,
## damage, status turns) and a detail id (the action for damage, the status for status/status_ended).
## Kinds: command, act, damage, interrupted, knocked_back, status, status_ended, down, fizzled, victory, defeat.

var kind: StringName
var unit_id: StringName
var value: int
var detail: StringName


func _init(event_kind: StringName, who: StringName, event_value: int = 0, event_detail: StringName = &"") -> void:
	kind = event_kind
	unit_id = who
	value = event_value
	detail = event_detail


func _to_string() -> String:
	return "%s:%s:%d" % [kind, unit_id, value]
