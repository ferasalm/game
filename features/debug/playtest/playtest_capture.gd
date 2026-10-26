class_name PlaytestCapture
extends Node
## purpose: F12 playtest capture: grabs the screen, lets Feras circle bugs and write a note, then saves shot.png,
## marked.png and state.json under inbox/playtest for Claude to read.

const MARK_WIDTH: float = 4.0

@export var source: Node
var out_root: String = "res://inbox/playtest"
var grab: Callable = Callable()

var _overlay: CanvasLayer
var _canvas: PlaytestCanvas
var _note: LineEdit
var _hint: Label
var _logger: PlaytestLogger
var _shot: Image
var _open: bool = false
var _closing: bool = false
var _paused_before: bool = false
var _focus_before: Control
var _mouse_before: Input.MouseMode = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = %Overlay
	_canvas = %Canvas
	_note = %Note
	_hint = %Hint
	_hint.text = tr("PLAYTEST_HINT")
	_note.placeholder_text = tr("PLAYTEST_NOTE")
	_overlay.visible = false
	if not OS.is_debug_build():
		set_process_input(false)
		set_process(false)
		return
	_logger = PlaytestLogger.new()
	OS.add_logger(_logger)


func _exit_tree() -> void:
	if _logger != null:
		OS.remove_logger(_logger)


func _input(event: InputEvent) -> void:
	if _open:
		_handle_open_input(event)
	elif not _closing and event.is_action_pressed("playtest_capture"):
		open_capture()
		get_viewport().set_input_as_handled()


## Grabs the screen first, then pauses and shows the drawing overlay.
func open_capture() -> void:
	if _open:
		return
	_shot = _take_shot()
	_paused_before = get_tree().paused
	_focus_before = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	_canvas.reset()
	_note.text = ""
	_overlay.visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_note.grab_focus()
	_open = true


func cancel_capture() -> void:
	if _open:
		_close()


func save_capture() -> void:
	if not _open:
		return
	_write_capture()
	_close()


func add_stroke(points: PackedVector2Array) -> void:
	_canvas.add_stroke(points)


func set_note(text: String) -> void:
	_note.text = text


func _handle_open_input(event: InputEvent) -> void:
	if event.is_action_pressed("playtest_capture") or _is_enter(event):
		save_capture()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		cancel_capture()
		get_viewport().set_input_as_handled()
	elif _is_undo(event):
		_canvas.strokes.undo()
		_canvas.queue_redraw()
		get_viewport().set_input_as_handled()


func _is_enter(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	return key.keycode in [KEY_ENTER, KEY_KP_ENTER] or key.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]


func _is_undo(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	return key.ctrl_pressed and key.keycode == KEY_Z


func _take_shot() -> Image:
	if grab.is_valid():
		return grab.call() as Image
	return get_viewport().get_texture().get_image()


func _write_capture() -> void:
	var msec: int = Time.get_ticks_msec() % 1000
	var stamp: String = PlaytestDump.folder_name(Time.get_datetime_string_from_system(), msec)
	var folder: String = out_root.path_join(stamp)
	DirAccess.make_dir_recursive_absolute(folder)
	_write_images(folder)
	_write_state(folder, stamp)
	_ensure_gdignore()
	print("PLAYTEST " + ProjectSettings.globalize_path(folder))


func _write_images(folder: String) -> void:
	if _shot == null or _shot.is_empty():
		return
	_shot.save_png(folder.path_join("shot.png"))
	var marked: Image = _shot.duplicate() as Image
	var xform: Transform2D = get_viewport().get_final_transform() * _canvas.get_global_transform_with_canvas()
	var width: int = maxi(1, roundi(MARK_WIDTH * xform.get_scale().x))
	PlaytestMarks.paint(marked, _canvas.strokes.strokes(), xform, Color.RED, width)
	marked.save_png(folder.path_join("marked.png"))


func _write_state(folder: String, stamp: String) -> void:
	var log_lines: Array = _logger.ring.lines() if _logger != null else []
	var data: Dictionary = PlaytestDump.build(_note.text, stamp, _scene_name(), _source_state(), log_lines)
	var file := FileAccess.open(folder.path_join("state.json"), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()


func _source_state() -> Dictionary:
	if source == null or not source.has_method("playtest_state"):
		return {}
	var state: Variant = source.call("playtest_state")
	if state is Dictionary:
		return state as Dictionary
	return {}


func _scene_name() -> String:
	var scene: Node = get_tree().current_scene
	return String(scene.name) if scene != null else ""


func _ensure_gdignore() -> void:
	var path: String = out_root.path_join(".gdignore")
	if FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.close()


func _close() -> void:
	_open = false
	_overlay.visible = false
	if _focus_before != null and is_instance_valid(_focus_before):
		_focus_before.grab_focus()
	else:
		_note.release_focus()
	Input.mouse_mode = _mouse_before
	_closing = true


func _process(_delta: float) -> void:
	if not _closing:
		return
	if Input.is_action_pressed("interact") or Input.is_action_pressed("back") or Input.is_action_pressed("menu"):
		return
	get_tree().paused = _paused_before
	_closing = false
