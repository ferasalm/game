class_name UiScreen
extends Control
## Base of every full menu (pause, items, shop, confirm, defeat). Pushed on the Screens stack: it fills the screen
## over a scrim, fades in, runs while the tree is paused, and routes `back` to on_back(). Subclasses override
## build(args) (add content under self), focus_default() and on_back(); they call close(result) when done.
## Use: Screens.push(screen) or Screens.open(&"id", args); listen to closed(result).

## Emitted once when the screen closes; Screens pops it on this signal.
signal closed(result: Variant)

## True: Screens pauses the tree while this screen is open.
var wants_pause: bool = true
## The CanvasLayer (UiLayers) Screens draws this screen on.
var layer_id: int = UiLayers.SCREEN
## Bottom prompt strip pairs: [{"key": "accept", "text": "UI_SELECT"}, ...] for the PromptStrip.
var prompts: Array[Dictionary] = []

var _closing: bool = false
var _scrim: ColorRect


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Ui.theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## Shows the screen: scrim, content from build(args), the entry fade. Screens calls it right after adding.
func open(args: Dictionary = {}) -> void:
	_scrim = ColorRect.new()
	_scrim.color = Ui.style().colour(&"c_scrim")
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_scrim)
	build(args)
	UiMotion.screen_in(self)
	focus_default()


## Closes the screen once: tells the stack (closed), then fades out and frees itself.
func close(result: Variant = null) -> void:
	if _closing:
		return
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit(result)
	if is_inside_tree():
		UiMotion.screen_out(self).finished.connect(queue_free)
	else:
		queue_free()


func is_closing() -> bool:
	return _closing


## The back action. Return true when handled (the default closes the screen).
func on_back() -> bool:
	close()
	return true


## The menu action while this screen is on top. The default ignores it.
func on_menu() -> bool:
	return false


## A covered screen (another pushed over it) stops reacting until it is on top again.
func set_covered(covered: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if covered else Node.PROCESS_MODE_ALWAYS


## Override: add this screen's controls under self.
func build(_args: Dictionary) -> void:
	pass


## Override: put keyboard/pad focus on the first control; Screens calls it again when this screen is uncovered.
func focus_default() -> void:
	pass


## Gives a button the qamariya sweep each time it takes focus.
func sweep_on_focus(control: Control) -> void:
	control.focus_entered.connect(UiSweep.start.bind(control))
	control.focus_exited.connect(UiSweep.clear.bind(control))
