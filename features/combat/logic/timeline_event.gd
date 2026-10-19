class_name TimelineEvent
extends RefCounted
## One thing that happened on the timeline, for the battle view and battle logs: what, who, and a value
## (the unit's new timeline position). Kinds: command, act, interrupted, knocked_back.

var kind: StringName
var unit_id: StringName
var value: int


func _init(event_kind: StringName, who: StringName, event_value: int = 0) -> void:
	kind = event_kind
	unit_id = who
	value = event_value


func _to_string() -> String:
	return "%s:%s:%d" % [kind, unit_id, value]
