extends SceneTree
## Headless test runner: runs every test_* method of every res://**/tests/test_*.gd file.
## Usage: tools/run_godot.sh -s res://tests/runner.gd [-- <path filter>]. Prints only failures plus one summary
## line, and exits 1 on any failure. tools/run_godot.sh also fails the run on any engine or script error.
## Tests start on the first frame, so the scene tree is ready for tests that add scenes to it.

var _started: bool = false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var filter: String = args[0] if args.size() > 0 else ""
	var passed: int = 0
	var failed: int = 0
	for path: String in _test_files("res://"):
		if not filter.is_empty() and not path.contains(filter):
			continue
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			print("FAIL %s: does not load" % path)
			failed += 1
			continue
		for method: Dictionary in script.get_script_method_list():
			var test_name: String = str(method["name"])
			if not test_name.begins_with("test_"):
				continue
			var case := script.new() as TestCase
			case.tree = self
			case.call(test_name)
			if case.failures.is_empty():
				passed += 1
				continue
			failed += 1
			for failure: String in case.failures:
				print("FAIL %s::%s: %s" % [path.get_file(), test_name, failure])
	print("tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir_path):
		if not sub.begins_with(".") and sub != "addons":
			out.append_array(_test_files(dir_path.path_join(sub)))
	if dir_path.get_file() == "tests":
		for file: String in DirAccess.get_files_at(dir_path):
			if file.begins_with("test_") and file.ends_with(".gd"):
				out.append(dir_path.path_join(file))
	return out
