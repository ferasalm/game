class_name DialogueBox
extends CanvasLayer
## The dialogue box: a chest-up portrait at the left overlapping a dark text box along the bottom, with the
## speaker's name in their colour and the line typed out quickly. Built in code. interact / ui_accept first
## completes the line, then moves to the next; the last advance hides the box and emits finished.
## Use: add it to the scene, call play(&"dialogue_id"), listen to finished.

## Emitted once when the last line has been dismissed.
signal finished(dialogue_id: StringName)

var _style: DialogueStyleDef
var _layout := DialogueLayout.new()
var _run: DialogueRun
var _dialogue_id: StringName = &""
var _typed: float = 0.0
var _total: int = 0
var _complete: bool = true
var _started_frame: int = -1
var _clock: float = 0.0


func _ready() -> void:
	_style = ContentDB.get_def("dialogue_style", &"default") as DialogueStyleDef
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_layout.build(root, _style)
	_set_playing_visuals(false)


## Starts a dialogue from the beginning; an unknown id is reported and ignored.
func play(dialogue_id: StringName) -> void:
	var def := ContentDB.get_def("dialogue", dialogue_id) as DialogueDef
	if def == null:
		push_warning("DialogueBox: no dialogue '%s'" % dialogue_id)
		return
	_dialogue_id = dialogue_id
	_run = DialogueRun.new(def)
	_started_frame = Engine.get_process_frames()
	if _run.is_finished():
		_finish()
		return
	_set_playing_visuals(true)
	_show_line()


func is_playing() -> bool:
	return _run != null


## Completes the typing of the current line, or moves to the next line (or ends) when it is complete.
func advance() -> void:
	if _run == null:
		return
	if not _complete:
		_type_all()
	elif _run.advance():
		_show_line()
	else:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if _run == null or Engine.get_process_frames() == _started_frame:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		advance()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_clock += delta
	if _run == null:
		return
	if not _complete:
		_typed += delta * _style.chars_per_second
		_layout.text_label.visible_characters = int(_typed)
		if int(_typed) >= _total:
			_type_all()
	_layout.arrow.position.y = sin(_clock * _style.arrow_speed) * _style.arrow_bob


func _show_line() -> void:
	var line: DialogueLine = _run.current()
	var speaker := ContentDB.get_def("speaker", line.speaker) as SpeakerDef
	_layout.name_label.text = tr(speaker.name_key)
	_layout.name_label.add_theme_color_override("font_color", speaker.color)
	_layout.text_label.text = tr(line.text_key)
	_total = _layout.text_label.text.length()
	_typed = 0.0
	_complete = false
	_layout.text_label.visible_characters = 0
	_layout.arrow.visible = false
	var real: bool = Portraits.has_real(line.speaker, line.expression)
	_layout.portrait.texture = Portraits.texture(line.speaker, line.expression)
	_layout.portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if real else CanvasItem.TEXTURE_FILTER_NEAREST


func _type_all() -> void:
	_complete = true
	_layout.text_label.visible_characters = -1
	_layout.arrow.visible = true


func _finish() -> void:
	_run = null
	_set_playing_visuals(false)
	finished.emit(_dialogue_id)


func _set_playing_visuals(playing: bool) -> void:
	visible = playing
