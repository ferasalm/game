class_name PlaytestLogger
extends Logger
## purpose: Catches engine errors and warnings into the capture's log ring without printing anything.

var ring: PlaytestLogRing = PlaytestLogRing.new()
var _mutex: Mutex = Mutex.new()


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	var detail: String = rationale if not rationale.is_empty() else code
	var prefix: String = "WARNING" if error_type == Logger.ERROR_TYPE_WARNING else "ERROR"
	_mutex.lock()
	ring.push("%s %s:%d %s" % [prefix, file, line, detail])
	_mutex.unlock()


func _log_message(message: String, error: bool) -> void:
	if not error:
		return
	_mutex.lock()
	ring.push(message)
	_mutex.unlock()
