class_name ToastHost
extends CanvasLayer
## Shows toasts top-centre one at a time (ToastQueue order): fade in, hold t_toast_hold, fade out, next. Created by
## Screens on the first toast and kept for the run. Use: Ui.toast("UI_TOAST_SAVED", &"good").

var _queue := ToastQueue.new()
var _root: Control
var _current: PanelContainer = null
var _current_text: String = ""
var _current_kind: StringName = &""


func _init() -> void:
	layer = UiLayers.TOAST
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_root = Ui.screen_root()
	add_child(_root)


func show_toast(text_key: String, kind: StringName = &"info", args: Array = []) -> void:
	_queue.push(text_key, kind, args)
	if _current == null:
		_next()


## The toast on screen now ("" when none) and its kind.
func current_text() -> String:
	return _current_text


func current_kind() -> StringName:
	return _current_kind


## Toasts waiting behind the one on screen.
func pending() -> int:
	return _queue.size()


func _next() -> void:
	var item: Dictionary = _queue.take()
	if item.is_empty():
		_current = null
		_current_text = ""
		_current_kind = &""
		return
	var style: UiStyleDef = Ui.style()
	_current_kind = item["kind"]
	var colours: Dictionary[StringName, StringName] = {&"info": &"c_text", &"good": &"c_good", &"bad": &"c_bad"}
	var tone: Color = style.colour(colours[_current_kind])
	_current = PanelContainer.new()
	_current.add_theme_stylebox_override("panel", UiBoxes.panel(style, &"plate", tone))
	_current.custom_minimum_size.x = style.size(&"s_toast_w")
	_current.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_current.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_current.offset_top = style.size(&"s_toast_top")
	_current.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_current_text = Ui.text(item["text"])
	if item.has("args") and not (item["args"] as Array).is_empty():
		_current_text = _current_text % item["args"]
	var line: Label = Ui.label(_current_text, &"NameLabel", tone)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_current.add_child(line)
	_current.modulate.a = 0.0
	_root.add_child(_current)
	AudioDirector.play_ui(&"ui_toast")
	var fade: float = style.time(&"t_toast_fade")
	var tween: Tween = UiMotion.tween(_current)
	tween.tween_property(_current, "modulate:a", 1.0, fade)
	tween.tween_interval(style.time(&"t_toast_hold"))
	tween.tween_property(_current, "modulate:a", 0.0, fade)
	tween.tween_callback(_finished.bind(_current))


func _finished(toast: PanelContainer) -> void:
	toast.queue_free()
	_next()
