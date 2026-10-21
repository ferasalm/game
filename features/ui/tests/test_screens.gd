extends TestCase
## The Screens stack: push/pop pause the tree and emit game_paused, focus returns to the control that had it, back
## goes to the top screen, an unhandled menu opens pause only while exploring with nothing open, screens open by id.


class Dummy extends UiScreen:
	var backs: int = 0
	var button: Button

	func build(_args: Dictionary) -> void:
		button = Button.new()
		add_child(button)

	func focus_default() -> void:
		if button != null:
			button.grab_focus()

	func on_back() -> bool:
		backs += 1
		return true


class Quiet extends Dummy:
	func _init() -> void:
		super()
		wants_pause = false


func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event


func _finish() -> void:
	Screens.clear()
	tree.paused = false
	Router.state = Router.STATE_TITLE


func test_layers_strictly_increase() -> void:
	var layers: Array[int] = UiLayers.ordered()
	for i: int in range(1, layers.size()):
		check(layers[i] > layers[i - 1], "layer %d is above %d" % [layers[i], layers[i - 1]])
	check(UiLayers.PAUSE < UiLayers.SCREEN and UiLayers.SCREEN < UiLayers.CONFIRM, "items draw over pause, confirm over both")


func test_push_pauses_and_pop_resumes() -> void:
	var events: Array[bool] = []
	var record: Callable = func(paused: bool) -> void: events.append(paused)
	EventBus.game_paused.connect(record)
	var screen := Dummy.new()
	Screens.push(screen)
	check(Screens.is_open() and tree.paused, "open screen pauses the tree")
	check_eq(Screens.top(), screen, "the pushed screen is on top")
	Screens.pop()
	check(not Screens.is_open() and not tree.paused, "the last pop resumes")
	EventBus.game_paused.disconnect(record)
	check_eq(events, [true, false] as Array[bool], "game_paused true then false")
	_finish()


func test_screen_that_does_not_want_pause_leaves_the_tree_running() -> void:
	Screens.push(Quiet.new())
	check(Screens.is_open() and not tree.paused, "no pause when wants_pause is false")
	_finish()


func test_pause_resets_time_scale() -> void:
	Engine.time_scale = 0.2
	Screens.push(Dummy.new())
	check_eq(Engine.time_scale, 1.0, "opening a pausing screen restores the time scale")
	_finish()


func test_focus_returns_to_the_previous_control() -> void:
	var before := Button.new()
	tree.root.add_child(before)
	before.grab_focus()
	var screen := Dummy.new()
	Screens.push(screen)
	check(screen.button.has_focus(), "the screen takes focus")
	Screens.pop()
	check(before.has_focus(), "focus goes back to where it was")
	before.queue_free()
	_finish()


func test_back_goes_to_the_top_screen_only() -> void:
	var low := Dummy.new()
	var high := Dummy.new()
	Screens.push(low)
	Screens.push(high)
	Screens._unhandled_input(_action(&"back"))
	check_eq(high.backs, 1, "top screen got back")
	check_eq(low.backs, 0, "the screen below did not")
	_finish()


func test_covered_screen_is_disabled_then_restored() -> void:
	var low := Dummy.new()
	Screens.push(low)
	Screens.push(Dummy.new())
	check_eq(low.process_mode, Node.PROCESS_MODE_DISABLED, "covered")
	Screens.pop()
	check_eq(low.process_mode, Node.PROCESS_MODE_ALWAYS, "uncovered runs again")
	_finish()


func test_menu_opens_pause_only_when_exploring_and_nothing_is_open() -> void:
	Router.state = Router.STATE_TITLE
	Screens._unhandled_input(_action(&"menu"))
	check(not Screens.is_open(), "no pause on the title")
	Router.state = Router.STATE_EXPLORING
	Screens._unhandled_input(_action(&"menu"))
	check(Screens.top() is PauseMenu, "menu opens pause while exploring")
	Screens._unhandled_input(_action(&"menu"))
	check(not Screens.is_open(), "a second menu resumes (the pause menu closes on menu)")
	_finish()


func test_back_closes_the_pause_menu() -> void:
	Router.state = Router.STATE_EXPLORING
	Screens.open(&"pause")
	Screens._unhandled_input(_action(&"back"))
	check(not Screens.is_open() and not tree.paused, "back closes pause and resumes")
	_finish()


func test_open_by_id_registers_and_refuses_unknown() -> void:
	check(Screens.has_screen(&"pause") and Screens.has_screen(&"equipment"), "pause and equipment are registered")
	Screens.register(&"dummy", func() -> Control: return Dummy.new())
	Screens.open(&"dummy")
	check(Screens.top() is Dummy and Screens.is_open_id(&"dummy"), "opened by id")
	Screens.open(&"dummy")
	check_eq(Screens.depth(), 1, "same id is never stacked twice")
	_finish()


func test_non_screen_is_refused() -> void:
	var plain := Control.new()
	Screens.push(plain)
	check(not Screens.is_open(), "a plain Control is not a screen")
	plain.free()
	_finish()


func test_confirm_defaults_to_no_and_back_answers_no() -> void:
	var dialog := ConfirmDialog.new()
	dialog.setup("PAUSE_TITLE", "PAUSE_CONFIRM_TITLE", false)
	var answers: Array[bool] = []
	dialog.answered.connect(func(yes: bool) -> void: answers.append(yes))
	Screens.push(dialog)
	check(dialog.no_button().has_focus(), "the safe button has focus")
	check_eq(Screens.top(), dialog, "dialog is on top")
	Screens._unhandled_input(_action(&"back"))
	check_eq(answers, [false] as Array[bool], "back is No")
	check(not Screens.is_open(), "the dialog closed")
	var again: Signal = Ui.confirm("PAUSE_QUIT", "PAUSE_CONFIRM_QUIT", true)
	var top: ConfirmDialog = Screens.top() as ConfirmDialog
	check(top != null and top.yes_button().has_focus(), "default_yes focuses Yes")
	check(again.get_object() == top, "Ui.confirm returns the dialog's signal")
	_finish()
