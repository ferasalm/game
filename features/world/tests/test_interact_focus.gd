class_name TestInteractFocus
extends TestCase
## purpose: Tests for interact focus camera framing ease, input eating, screen chaining and camera restore.

var _parent: Node3D
var _world_cam: Camera3D
var _spot: Node3D
var _player: Player
var _shot: FocusShotDef
var _focus: InteractFocus


func _setup_scene() -> void:
	_parent = Node3D.new()
	tree.root.add_child(_parent)
	_world_cam = Camera3D.new()
	_world_cam.position = Vector3(0.0, 5.0, 10.0)
	_world_cam.fov = 60.0
	_parent.add_child(_world_cam)
	_world_cam.make_current()
	_spot = Node3D.new()
	_spot.position = Vector3(10.0, 0.0, 5.0)
	_parent.add_child(_spot)
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	_player = Player.new(rules)
	_parent.add_child(_player)
	_player.set_active(true)
	_shot = FocusShotDef.new()
	_shot.id = &"test_shot"
	_shot.offset = Vector3(0.0, 2.0, 3.0)
	_shot.look_at = Vector3(0.0, 1.0, 0.0)
	_shot.fov = 35.0
	_focus = InteractFocus.new()
	_parent.add_child(_focus)
	Screens.register(&"test_screen", func() -> Control: return UiScreen.new())


func _teardown_scene() -> void:
	Screens.clear()
	if _parent != null and is_instance_valid(_parent):
		_parent.free()
	_parent = null


func test_focus_open_eases_camera_and_opens_screen_after_ease() -> void:
	_setup_scene()
	var orig_trans: Transform3D = _world_cam.global_transform
	var orig_fov: float = _world_cam.fov
	var zoom_time: float = Ui.style().time(&"t_focus_zoom")
	_focus.focus_open(_spot, _shot, _player, &"test_screen")
	check(not _player.visible, "player inactive and hidden during ease")
	check(not Screens.is_open_id(&"test_screen"), "screen does not open before ease finishes")
	var focus_cam: Camera3D = _parent.get_viewport().get_camera_3d()
	check(focus_cam != _world_cam, "current camera is focus camera during ease")
	_focus.advance(zoom_time)
	check(Screens.is_open_id(&"test_screen"), "screen opened only after ease finished")
	var expected_pos: Vector3 = _spot.global_position + _shot.offset
	check(focus_cam.global_position.distance_to(expected_pos) < 0.05, "focus camera reached target position")
	check(is_equal_approx(focus_cam.fov, _shot.fov), "focus camera reached target fov")
	Screens.pop()
	_focus.advance(zoom_time)
	check(_parent.get_viewport().get_camera_3d() == _world_cam, "world camera is current after close ease")
	check(not is_instance_valid(focus_cam) or focus_cam.is_queued_for_deletion(), "focus camera freed")
	check(_world_cam.global_transform == orig_trans, "world camera transform was never written")
	check(is_equal_approx(_world_cam.fov, orig_fov), "world camera fov was never written")
	check(_player.visible, "player active again after ease back")
	_teardown_scene()


func test_missing_focus_shot_opens_at_once_with_no_ease() -> void:
	_setup_scene()
	_focus.focus_open(_spot, null, _player, &"test_screen")
	check(Screens.is_open_id(&"test_screen"), "missing FocusShotDef opens screen immediately")
	check(_parent.get_viewport().get_camera_3d() == _world_cam, "world camera remains current")
	_teardown_scene()


func test_sabil_two_screen_flow_eases_back_once_after_last() -> void:
	_setup_scene()
	var zoom_time: float = Ui.style().time(&"t_focus_zoom")
	_focus.focus_open(_spot, _shot, _player, Screens.SABIL_ID)
	_focus.advance(zoom_time)
	check(Screens.is_open_id(Screens.SABIL_ID), "sabil screen is open")
	var sabil_screen: SabilScreen = Screens.top() as SabilScreen
	sabil_screen.choose(SabilScreen.DRINK)
	var picker := Screens.open(Screens.SLOT_PICKER_ID, {"mode": SlotPickerScreen.MODE_SAVE}) as SlotPickerScreen
	check(Screens.is_open_id(Screens.SLOT_PICKER_ID), "slot picker is open")
	check(_parent.get_viewport().get_camera_3d() != _world_cam, "focus camera stays current across screen chain")
	picker.close(null)
	check(not Screens.is_open(), "all screens closed")
	_focus.advance(zoom_time)
	check(_parent.get_viewport().get_camera_3d() == _world_cam, "world camera restored after last screen closes")
	_teardown_scene()


func test_interact_during_ease_does_nothing() -> void:
	_setup_scene()
	_focus.focus_open(_spot, _shot, _player, &"test_screen")
	var second: UiScreen = await _focus.focus_open(_spot, _shot, _player, &"test_screen")
	check(second == null, "second focus_open during ease is ignored")
	var zoom_time: float = Ui.style().time(&"t_focus_zoom")
	_focus.advance(zoom_time)
	Screens.pop()
	_focus.advance(zoom_time)
	_teardown_scene()


func test_input_eaten_during_ease() -> void:
	_setup_scene()
	_focus.focus_open(_spot, _shot, _player, &"test_screen")
	var event := InputEventKey.new()
	event.pressed = true
	_focus._input(event)
	check(_focus.get_viewport().is_input_handled(), "input is marked handled during ease")
	var zoom_time: float = Ui.style().time(&"t_focus_zoom")
	_focus.advance(zoom_time)
	Screens.pop()
	_focus.advance(zoom_time)
	_teardown_scene()
