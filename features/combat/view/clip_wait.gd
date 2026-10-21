class_name ClipWait
extends RefCounted
## Waits for a named clip event of one CharacterVisual (&"impact": the hit lands, &"end": the clip is over). Make it
## BEFORE starting the clip, so an event that fires at once is not missed, then `await wait.until(event, host, limit)`.
## A source that never sends the event (a stand-in, a clip without an impact frame) cannot hang the fight: after
## `limit` seconds of game time (pause-safe) the wait ends and timed_out() is true. Call release() when done.

signal _resolved

var _visual: CharacterVisual
var _seen: Array[StringName] = []
var _wanted: StringName = &""
var _done: bool = false
var _timed_out: bool = false
var _token: int = 0  ## which until() a timeout belongs to (an old wait's timer must not end a newer one)


func _init(visual: CharacterVisual) -> void:
	_visual = visual
	visual.clip_event.connect(_on_event)


## Returns once the event has been seen (at once if it already was) or after limit seconds.
func until(event: StringName, host: Node, limit: float) -> void:
	if _seen.has(event):
		return
	_wanted = event
	_done = false
	_token += 1
	PauseWait.seconds(host, limit).connect(_on_timeout.bind(_token))
	await _resolved


func has_seen(event: StringName) -> bool:
	return _seen.has(event)


func timed_out() -> bool:
	return _timed_out


func release() -> void:
	if is_instance_valid(_visual) and _visual.clip_event.is_connected(_on_event):
		_visual.clip_event.disconnect(_on_event)


func _on_event(event: StringName) -> void:
	_seen.append(event)
	if event == _wanted:
		_resolve()


func _on_timeout(token: int) -> void:
	if token == _token and not _done:
		_timed_out = true
		_resolve()


func _resolve() -> void:
	if not _done:
		_done = true
		_resolved.emit()
