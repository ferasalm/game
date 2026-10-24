class_name ToastQueue
extends RefCounted
## Pure: toasts wait in order and are shown one at a time. A kind is info, good or bad; an unknown kind is info.

const KINDS: Array[StringName] = [&"info", &"good", &"bad"]

var _items: Array[Dictionary] = []


func push(text_key: String, kind: StringName = &"info", args: Array = []) -> void:
	var item: Dictionary = {"text": text_key, "kind": kind if KINDS.has(kind) else &"info"}
	if not args.is_empty():
		item["args"] = args
	_items.append(item)


func size() -> int:
	return _items.size()


## The next toast as {"text": key, "kind": kind}; an empty dictionary when none waits.
func take() -> Dictionary:
	return {} if _items.is_empty() else _items.pop_front()
