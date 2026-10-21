class_name FollowGuard
extends RefCounted
## Keeps the follower from sticking: it asks to be put back on the leader's trail when it is farther than the leash,
## or when it wanted to move but barely got closer to the target (wedged on a corner) for stuck_seconds. Pure: the caller feeds it the
## wanted step and the step that really happened each frame.

var _stuck_seconds: float
var _leash: float
var _min_ratio: float
var _stuck_for: float = 0.0


## leash: metres from the trail target past which she snaps; min_ratio: moved/wanted below this counts as stuck.
func _init(stuck_seconds: float, leash: float, min_ratio: float) -> void:
	_stuck_seconds = stuck_seconds
	_leash = leash
	_min_ratio = min_ratio


## gap: distance to the trail target; wanted and moved: the step length she tried and how much closer to the target it got.
## Returns true when she should snap to the target now.
func update(delta: float, gap: float, wanted: float, moved: float) -> bool:
	if gap > _leash:
		_stuck_for = 0.0
		return true
	if wanted > 0.0 and moved < wanted * _min_ratio:
		_stuck_for += delta
	else:
		_stuck_for = 0.0
	if _stuck_for >= _stuck_seconds:
		_stuck_for = 0.0
		return true
	return false


func reset() -> void:
	_stuck_for = 0.0
