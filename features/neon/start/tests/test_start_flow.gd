class_name TestStartFlow
extends TestCase
## Headless tests for StartFlow clip loading, done emission, mashing and localized labels.

const SCENE_PATH: String = "res://features/neon/start/start_flow.tscn"
const JSON_PATH: String = "res://content/neon/start_flow.json"
const CSV_PATH: String = "res://localization/neon_start.csv"


func test_clips_load_as_video_streams() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(JSON_PATH))
	check(data is Dictionary, "start_flow.json parses")
	var item: Dictionary = (data as Dictionary)["items"][0]
	for key: String in ["title_clip", "window_push_clip", "hero_pick_clip", "rydan_panel_clip", "rydan_reaction_clip", "launch_clip"]:
		var path: String = str(item[key])
		var stream: Resource = load(path)
		check(stream != null, "Clip exists and loads: %s" % path)
		check(stream is VideoStream, "Clip is a VideoStream: %s" % path)


func test_done_fires_with_chosen_difficulty() -> void:
	var flow := _make_flow()
	var emitted_diff: Array[StringName] = []
	flow.done.connect(func(diff: StringName) -> void: emitted_diff.append(diff))

	flow.steps.state = StartSteps.STATE_PANEL
	flow.steps.difficulty = StartSteps.DIFF_HARD
	flow.steps.confirm()
	flow.steps.clip_done()
	flow.steps.clip_done()
	flow._apply_state(flow.steps.state)

	check_eq(emitted_diff.size(), 1, "done signal fired once")
	if emitted_diff.size() > 0:
		check_eq(emitted_diff[0], StartSteps.DIFF_HARD, "done fired with chosen difficulty hard")
	_free_flow(flow)


func test_done_fires_with_normal_difficulty() -> void:
	var flow := _make_flow()
	var emitted_diff: Array[StringName] = []
	flow.done.connect(func(diff: StringName) -> void: emitted_diff.append(diff))

	flow.steps.state = StartSteps.STATE_PANEL
	flow.steps.difficulty = StartSteps.DIFF_NORMAL
	flow.steps.confirm()
	flow.steps.clip_done()
	flow.steps.clip_done()
	flow._apply_state(flow.steps.state)

	check_eq(emitted_diff.size(), 1, "done signal fired once")
	if emitted_diff.size() > 0:
		check_eq(emitted_diff[0], StartSteps.DIFF_NORMAL, "done fired with default difficulty normal")
	_free_flow(flow)


func test_done_emits_only_once() -> void:
	var flow := _make_flow()
	var emitted: Array[StringName] = []
	flow.done.connect(func(diff: StringName) -> void: emitted.append(diff))
	flow.steps.state = StartSteps.STATE_DONE
	flow._apply_state(flow.steps.state)
	flow._apply_state(flow.steps.state)
	check_eq(emitted.size(), 1, "done is emitted exactly once")
	_free_flow(flow)


func test_mashing_emits_done_at_most_once() -> void:
	var flow := _make_flow()
	var emitted: Array[StringName] = []
	flow.done.connect(func(diff: StringName) -> void: emitted.append(diff))
	var states: Array[StringName] = [
		StartSteps.STATE_TITLE,
		StartSteps.STATE_MENU,
		StartSteps.STATE_WINDOW_PUSH,
		StartSteps.STATE_PICK,
		StartSteps.STATE_PANEL,
		StartSteps.STATE_REACTION,
		StartSteps.STATE_LAUNCH,
	]
	for state: StringName in states:
		flow.steps.state = state
		flow.steps.menu_cursor = StartSteps.MENU_NEW_GAME
		flow.steps.hero = StartSteps.HERO_RYDAN
		flow.steps.difficulty = StartSteps.DIFF_NORMAL
		flow.steps.quit_requested = false
		flow._busy_left = 0.0
		flow._done_emitted = false
		flow._transition_token = 0
		emitted.clear()
		for i: int in 10:
			flow.handle_action(&"confirm")
		check(emitted.size() <= 1, "state %s emits done at most once (got %d)" % [state, emitted.size()])
	_free_flow(flow)


func test_visible_labels_use_localization_keys() -> void:
	var flow := _make_flow()
	var keys: PackedStringArray = _neon_keys()
	check(keys.size() > 0, "localization keys load")
	for state: String in ["TITLE", "MENU", "PICK", "PANEL"]:
		flow.set_state_for_shot(state)
		var labels: Array[Label] = []
		_collect_labels(flow, labels)
		for label: Label in labels:
			if not label.is_visible_in_tree() or label.text.is_empty():
				continue
			check(_matches_key(label.text, keys), "label %s text '%s' in %s is a localization key result" % [label.name, label.text, state])
	_free_flow(flow)


func _make_flow() -> StartFlow:
	var scene: PackedScene = load(SCENE_PATH) as PackedScene
	check(scene != null, "start_flow.tscn loads")
	var flow: StartFlow = scene.instantiate() as StartFlow
	check(flow != null, "start_flow instantiates as StartFlow")
	tree.root.add_child(flow)
	return flow


func _free_flow(flow: StartFlow) -> void:
	tree.root.remove_child(flow)
	flow.free()


func _neon_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for line: String in FileAccess.get_file_as_string(CSV_PATH).split("\n"):
		if line.begins_with("NEON_"):
			keys.append(line.get_slice(",", 0))
	return keys


func _matches_key(text: String, keys: PackedStringArray) -> bool:
	for key: String in keys:
		if text == TranslationServer.translate(key):
			return true
	return false


func _collect_labels(node: Node, out: Array[Label]) -> void:
	for child: Node in node.get_children():
		if child is Label:
			out.append(child as Label)
		_collect_labels(child, out)
