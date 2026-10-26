class_name TestStartFlow
extends TestCase
## Headless tests for StartFlow clip loading and done signal emission.


func test_clips_load_as_video_streams() -> void:
	var def := StartFlowDef.new()
	var clip_paths: Array[String] = [
		def.title_clip,
		def.window_push_clip,
		def.hero_pick_clip,
		def.rydan_panel_clip,
		def.rydan_reaction_clip,
		def.launch_clip
	]
	for path: String in clip_paths:
		var stream: Resource = load(path)
		check(stream != null, "Clip exists and loads: %s" % path)
		check(stream is VideoStream, "Clip is a VideoStream: %s" % path)


func test_done_fires_with_chosen_difficulty() -> void:
	var scene: PackedScene = load("res://features/neon/start/start_flow.tscn") as PackedScene
	check(scene != null, "start_flow.tscn loads")

	var flow := scene.instantiate() as StartFlow
	check(flow != null, "start_flow instantiates as StartFlow")
	tree.root.add_child(flow)

	var emitted_diff: Array[StringName] = []
	flow.done.connect(func(diff: StringName) -> void: emitted_diff.append(diff))

	# Simulate choosing Hard difficulty and completing the flow
	flow.steps.state = StartSteps.STATE_PANEL
	flow.steps.difficulty = StartSteps.DIFF_HARD
	flow.steps.confirm()  # -> REACTION
	flow.steps.clip_done()  # -> LAUNCH
	flow.steps.clip_done()  # -> DONE
	flow._apply_state(flow.steps.state)

	check_eq(emitted_diff.size(), 1, "done signal fired once")
	if emitted_diff.size() > 0:
		check_eq(emitted_diff[0], StartSteps.DIFF_HARD, "done fired with chosen difficulty hard")

	tree.root.remove_child(flow)
	flow.free()


func test_done_fires_with_normal_difficulty() -> void:
	var scene: PackedScene = load("res://features/neon/start/start_flow.tscn") as PackedScene
	var flow := scene.instantiate() as StartFlow
	tree.root.add_child(flow)

	var emitted_diff: Array[StringName] = []
	flow.done.connect(func(diff: StringName) -> void: emitted_diff.append(diff))

	flow.steps.state = StartSteps.STATE_PANEL
	flow.steps.difficulty = StartSteps.DIFF_NORMAL
	flow.steps.confirm()  # -> REACTION
	flow.steps.clip_done()  # -> LAUNCH
	flow.steps.clip_done()  # -> DONE
	flow._apply_state(flow.steps.state)

	check_eq(emitted_diff.size(), 1, "done signal fired once")
	if emitted_diff.size() > 0:
		check_eq(emitted_diff[0], StartSteps.DIFF_NORMAL, "done fired with default difficulty normal")

	tree.root.remove_child(flow)
	flow.free()
