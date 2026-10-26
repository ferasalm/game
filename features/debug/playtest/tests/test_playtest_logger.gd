class_name TestPlaytestLogger
extends TestCase
## purpose: PlaytestLogger records engine errors and error messages into its ring, ignores plain messages, and the
## ring keeps only the newest lines.


func test_log_error_fills_the_ring() -> void:
	var logger := PlaytestLogger.new()
	var backtraces: Array[ScriptBacktrace] = []
	logger._log_error("func", "res://x.gd", 3, "code", "rationale", false, Logger.ERROR_TYPE_ERROR, backtraces)
	check_eq(logger.ring.lines().size(), 1, "one line recorded")
	check((logger.ring.lines()[0] as String).contains("res://x.gd:3"), "the file and line are kept")
	check((logger.ring.lines()[0] as String).contains("rationale"), "the rationale is used")


func test_log_message_only_records_errors() -> void:
	var logger := PlaytestLogger.new()
	logger._log_message("plain", false)
	check_eq(logger.ring.lines().size(), 0, "a plain message is ignored")
	logger._log_message("bad", true)
	check_eq(logger.ring.lines().size(), 1, "an error message is kept")


func test_the_ring_keeps_the_newest_fifty() -> void:
	var ring := PlaytestLogRing.new()
	for i: int in 60:
		ring.push("line %d" % i)
	check_eq(ring.lines().size(), PlaytestLogRing.CAP, "the ring is capped")
	check_eq(ring.lines()[0], "line 10", "the oldest lines are dropped")
	check_eq(ring.lines()[PlaytestLogRing.CAP - 1], "line 59", "the newest line stays")
