class_name TestCase
extends RefCounted
## Base class for test files. tests/runner.gd makes a fresh instance for every test_* method, sets tree,
## calls the method, then reports each failure recorded with check() or check_eq().

var tree: SceneTree
var failures: PackedStringArray = []


func check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


## Equal value and equal type (an int 5 does not equal a float 5.0 here).
func check_eq(actual: Variant, expected: Variant, what: String) -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s: expected %s, got %s" % [what, var_to_str(expected), var_to_str(actual)])
