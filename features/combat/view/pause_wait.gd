class_name PauseWait
extends Node
## The one pause-safe wait of the battle view. `await PauseWait.seconds(host, t)` resumes after t seconds of game time
## and stops counting while the tree is paused (a SceneTreeTimer made with the default arguments keeps running during
## a pause). real_time = true counts wall-clock seconds even under a hitstop's low Engine.time_scale.
## The wait is a child of host: if the host leaves the tree the wait never resumes.

## Emitted once when the time is up.
signal done

const MIN_SCALE: float = 0.001  ## guards the real-time division

var _left: float = 0.0
var _real_time: bool = false


## Starts a wait under host and returns the signal to await.
static func seconds(host: Node, time: float, real_time: bool = false) -> Signal:
	var wait := PauseWait.new()
	wait._left = time
	wait._real_time = real_time
	wait.process_mode = Node.PROCESS_MODE_PAUSABLE
	host.add_child(wait)
	return wait.done


func _process(delta: float) -> void:
	_left -= delta / maxf(Engine.time_scale, MIN_SCALE) if _real_time else delta
	if _left <= 0.0:
		set_process(false)
		done.emit()
		queue_free()
