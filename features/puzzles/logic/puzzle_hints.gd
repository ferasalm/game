class_name PuzzleHints
extends RefCounted
## purpose: Computes how many puzzle hints are due based on elapsed stalled time.


static func hints_due(hint_secs: Array[int], stalled_secs: float) -> int:
	var count: int = 0
	for sec: int in hint_secs:
		if stalled_secs >= float(sec):
			count += 1
	return count
