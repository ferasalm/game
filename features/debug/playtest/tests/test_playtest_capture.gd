class_name TestPlaytestCapture
extends TestCase
## purpose: PlaytestCapture pauses while it is open, cancels back to the previous pause state after the input is
## released, and saves shot.png, marked.png and state.json from an injected grab.


func _capture() -> PlaytestCapture:
	var scene := load("res://features/debug/playtest/playtest_capture.tscn") as PackedScene
	var capture := scene.instantiate() as PlaytestCapture
	capture.out_root = SaveService.test_dir_for(ProjectSettings.globalize_path("res://")).path_join("playtest")
	capture.grab = func() -> Image: return Image.create(8, 8, false, Image.FORMAT_RGBA8)
	tree.root.add_child(capture)
	return capture


func _cleanup(capture: PlaytestCapture) -> void:
	tree.paused = false
	capture.queue_free()
	SaveService.empty_dir(capture.out_root)
	DirAccess.remove_absolute(capture.out_root)


func test_open_pauses_and_cancel_restores_after_release() -> void:
	tree.paused = false
	var capture: PlaytestCapture = _capture()
	capture.open_capture()
	check(tree.paused, "opening pauses the game")
	capture.cancel_capture()
	check(tree.paused, "it stays paused until the input is released")
	capture._process(0.0)
	check(not tree.paused, "it unpauses on the release frame")
	_cleanup(capture)


func test_save_writes_three_files_and_restores_pause() -> void:
	tree.paused = false
	var capture: PlaytestCapture = _capture()
	var shot := Image.create(64, 36, false, Image.FORMAT_RGBA8)
	shot.fill(Color.BLUE)
	capture.grab = func() -> Image: return shot
	capture.open_capture()
	check(tree.paused, "paused while open")
	capture.set_note("test note")
	capture.add_stroke(PackedVector2Array([Vector2(5.0, 5.0), Vector2(40.0, 20.0)]))
	capture.save_capture()
	capture._process(0.0)
	check(not tree.paused, "the pause is restored after saving")
	var folders: PackedStringArray = DirAccess.get_directories_at(capture.out_root)
	check_eq(folders.size(), 1, "one capture folder")
	if folders.size() == 1:
		var folder: String = capture.out_root.path_join(folders[0])
		for name: String in ["shot.png", "marked.png", "state.json"]:
			check(FileAccess.file_exists(folder.path_join(name)), name + " was written")
	_cleanup(capture)
