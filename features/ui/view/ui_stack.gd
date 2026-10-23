extends CanvasLayer
## Screen stack (autoload Screens): push/pop UiScreens (each on its own UiLayers layer), pause the tree while one
## wants it, restore focus when one closes, route `back` / `menu` input, and open the pause menu on `menu` when the
## game is exploring and nothing is open. Screens are also opened by id (register / open). Lives for the whole run.

## Emitted when the number of open screens changes (HUDs can hide while a menu is up).
signal stack_changed(depth: int)
signal screen_opened(screen_id: StringName)
signal screen_closed(screen_id: StringName)

const PAUSE_ID: StringName = &"pause"
const EQUIPMENT_ID: StringName = &"equipment"
const SABIL_ID: StringName = &"sabil"  ## closes with &"drink" or &"leave"
const DEFEAT_ID: StringName = &"defeat"  ## closes with &"retry", &"load" or &"title"
const WORKSHOP_ID: StringName = &"workshop"
const TITLE_ID: StringName = &"title"
const SLOT_PICKER_ID: StringName = &"slot_picker"

var _stack: Array[UiScreen] = []
var _hosts: Dictionary[int, CanvasLayer] = {}
var _focus_back: Dictionary[int, Control] = {}
var _factories: Dictionary[StringName, Callable] = {}
var _paused_by_us: bool = false
var _toasts: ToastHost = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = UiLayers.SCREEN
	register(PAUSE_ID, func() -> Control: return PauseMenu.new())
	register(EQUIPMENT_ID, func() -> Control: return EquipmentMenu.new())
	register(ItemsScreen.ID, func() -> Control: return ItemsScreen.new())
	register(ShopScreen.ID, func() -> Control: return ShopScreen.new())
	register(SABIL_ID, func() -> Control: return SabilScreen.new())
	register(DEFEAT_ID, func() -> Control: return DefeatScreen.new())
	register(WORKSHOP_ID, func() -> Control: return WorkshopMenu.new())
	register(TITLE_ID, func() -> Control: return UiScreen.new())
	register(SLOT_PICKER_ID, func() -> Control: return SlotPickerScreen.new())
	Router.flow_changed.connect(_on_flow_changed)


## True while any screen is open.
func is_open() -> bool:
	return not _stack.is_empty()


func depth() -> int:
	return _stack.size()


func top() -> UiScreen:
	return null if _stack.is_empty() else _stack[-1]


## True when a screen with this registered id is open anywhere in the stack.
func is_open_id(id: StringName) -> bool:
	for screen: UiScreen in _stack:
		if screen.has_meta(&"screen_id") and screen.get_meta(&"screen_id") == id:
			return true
	return false


## Puts a screen on top, opens it with no arguments and takes over pause and focus. Non-UiScreens are refused.
func push(screen: Control) -> void:
	_push(screen as UiScreen, {})


## Closes the top screen (result null). Does nothing when the stack is empty.
func pop() -> void:
	if not _stack.is_empty():
		_stack[-1].close(null)


## Closes every screen, top first (Router does this when the flow leaves exploring).
func clear() -> void:
	while not _stack.is_empty():
		_stack[-1].close(null)


## Registers a screen factory (a Callable returning a UiScreen) under an id, for open(). Re-registering replaces.
func register(id: StringName, factory: Callable) -> void:
	_factories[id] = factory


func has_screen(id: StringName) -> bool:
	return _factories.has(id)


## Builds the registered screen and pushes it with args; an unknown id is a warning. The same id is never stacked twice.
## Returns the screen (listen to its `closed(result)`), or null when refused.
func open(id: StringName, args: Dictionary = {}) -> UiScreen:
	if not _factories.has(id):
		push_warning("Screens: no screen registered as %s" % id)
		return null
	if is_open_id(id):
		return null
	var screen := _factories[id].call() as UiScreen
	if screen != null:
		screen.set_meta(&"screen_id", id)
		_push(screen, args)
	return screen


## Queues a toast on the toast layer (Ui.toast calls this).
func toast(text_key: String, kind: StringName = &"info") -> void:
	if _toasts == null:
		_toasts = ToastHost.new()
		add_child(_toasts)
	_toasts.show_toast(text_key, kind)


func notify_opened(id: StringName) -> void:
	screen_opened.emit(id)


func notify_closed(id: StringName) -> void:
	screen_closed.emit(id)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		if event.is_action_pressed(&"menu") and Router.is_exploring():
			open(PAUSE_ID)
			get_viewport().set_input_as_handled()
		return
	var screen: UiScreen = _stack[-1]
	if event.is_action_pressed(&"back"):
		screen.on_back()
	elif event.is_action_pressed(&"menu"):
		screen.on_menu()
	else:
		return
	get_viewport().set_input_as_handled()


func _push(screen: UiScreen, args: Dictionary) -> void:
	if screen == null:
		push_warning("Screens.push: only UiScreen nodes can be pushed")
		return
	var below: UiScreen = top()
	_focus_back[screen.get_instance_id()] = get_viewport().gui_get_focus_owner()
	if below != null:
		below.set_covered(true)
	var host := CanvasLayer.new()
	host.layer = screen.layer_id
	host.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(host)
	host.add_child(screen)
	_hosts[screen.get_instance_id()] = host
	_stack.append(screen)
	screen.closed.connect(_on_closed.bind(screen))
	_refresh_pause()
	screen.open(args)
	var screen_id: StringName = screen.get_meta(&"screen_id", &"")
	screen_opened.emit(screen_id)
	stack_changed.emit(_stack.size())


func _on_closed(_result: Variant, screen: UiScreen) -> void:
	var key: int = screen.get_instance_id()
	_stack.erase(screen)
	var host: CanvasLayer = _hosts.get(key)
	_hosts.erase(key)
	if host != null:
		screen.tree_exited.connect(host.queue_free)
	var back: Variant = _focus_back.get(key)
	_focus_back.erase(key)
	var now: UiScreen = top()
	if now != null:
		now.set_covered(false)
	if back is Control and is_instance_valid(back) and (back as Control).is_visible_in_tree():
		(back as Control).grab_focus()
	elif now != null:
		now.focus_default()
	_refresh_pause()
	var screen_id: StringName = screen.get_meta(&"screen_id", &"")
	screen_closed.emit(screen_id)
	stack_changed.emit(_stack.size())


## The tree is paused exactly while some open screen wants it; entering pause resets the time scale (no stuck hitstop).
func _refresh_pause() -> void:
	var want: bool = false
	for screen: UiScreen in _stack:
		want = want or screen.wants_pause
	if want == _paused_by_us:
		return
	_paused_by_us = want
	if want:
		Engine.time_scale = 1.0
	get_tree().paused = want
	EventBus.game_paused.emit(want)


func _on_flow_changed(state: StringName) -> void:
	if state != Router.STATE_EXPLORING:
		clear()
