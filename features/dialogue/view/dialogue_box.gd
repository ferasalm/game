class_name DialogueBox
extends CanvasLayer
## The dialogue box, Hades II style: a big portrait slides in when the speaker changes, a nameplate sits on the box,
## lines are typed out, and choice buttons offer branching dialogue.

## Emitted once when the conversation has ended (last line dismissed, ceased, or choice ended).
signal finished(dialogue_id: StringName)

var _style: DialogueStyleDef
var _layout := DialogueLayout.new()
var _run: DialogueRun
var _dialogue_id: StringName = &""
var _speaker: StringName = &""
var _typing: Tween = null
var _slide: Tween = null
var _started_frame: int = -1
var _clock: float = 0.0
var _choice_list: DialogueChoiceList
var _showing_choices: bool = false


func _ready() -> void:
	layer = UiLayers.DIALOGUE
	_style = ContentDB.get_def("dialogue_style", &"default") as DialogueStyleDef
	var root: Control = Ui.screen_root()
	add_child(root)
	_layout.build(root, _style)
	_choice_list = DialogueChoiceList.new(_layout.choice_box)
	_set_playing_visuals(false)


func play(dialogue_id: StringName) -> void:
	var def := ContentDB.get_def("dialogue", dialogue_id) as DialogueDef
	if def == null:
		push_warning("DialogueBox: no dialogue '%s'" % dialogue_id)
		return
	_dialogue_id = dialogue_id
	_run = DialogueRun.new(def)
	_speaker = &""
	_started_frame = Engine.get_process_frames()
	if _run.is_finished():
		_finish()
		return
	_set_playing_visuals(true)
	_show_line()


func is_playing() -> bool:
	return _run != null


func dialogue_id() -> StringName:
	return _dialogue_id


func is_typing() -> bool:
	return _run != null and UiType.is_typing(_layout.text_label, _typing)


func choice_buttons() -> Array[Button]:
	return _choice_list.buttons if _choice_list != null else []


func is_showing_choices() -> bool:
	return _showing_choices


func choose(index: int) -> void:
	_on_choice_pressed(index)


func advance() -> void:
	if _run == null:
		return
	AudioDirector.play_ui(&"ui_confirm")
	if is_typing():
		_type_all()
		if _run.has_choices():
			_display_choices()
	elif _run.has_choices():
		_display_choices()
	elif _run.advance():
		_show_line()
	else:
		_finish()


func cease() -> void:
	if _run != null:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if _run == null or Engine.get_process_frames() == _started_frame:
		return
	if _showing_choices:
		if event.is_action_pressed(&"back"):
			cease()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"back"):
		cease()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_clock += delta
	if _run != null:
		_layout.arrow.position.y = sin(_clock * _style.arrow_speed) * _style.arrow_bob
		_layout.arrow.visible = not is_typing() and not _showing_choices
		if not is_typing() and _run.has_choices() and not _showing_choices:
			_display_choices()


func _show_line() -> void:
	_clear_choices()
	var line: DialogueLine = _run.current()
	var speaker := ContentDB.get_def("speaker", line.speaker) as SpeakerDef
	_layout.name_label.text = Ui.text(speaker.name_key)
	_layout.epithet_label.text = Ui.text(speaker.epithet_key) if not speaker.epithet_key.is_empty() else ""
	_layout.epithet_label.visible = not _layout.epithet_label.text.is_empty()
	var real: bool = Portraits.has_real(line.speaker, line.expression)
	_layout.portrait.flip_h = speaker.portrait_flip and real
	_layout.portrait.texture = Portraits.texture(line.speaker, line.expression)
	if line.speaker != _speaker:
		_slide_portrait_in()
	_speaker = line.speaker
	_typing = Ui.type_text(_layout.text_label, Ui.text(line.text_key))
	_layout.arrow.visible = false


func _display_choices() -> void:
	if _showing_choices or _run == null or not _run.has_choices():
		return
	_showing_choices = true
	_layout.arrow.visible = false
	_choice_list.show_choices(_run.choices(), _on_choice_pressed)


func _on_choice_pressed(index: int) -> void:
	if _run == null or not _run.has_choices():
		return
	AudioDirector.play_ui(&"ui_confirm")
	var choice: DialogueChoice = _run.choose(index)
	_clear_choices()
	DialogueEffects.apply_all(choice.effects)
	if choice.next.is_empty() or choice.next == &"end":
		_finish()
	elif choice.next == &"chat" or choice.next == &"abu_nabil_chat":
		var talk_def := ContentDB.get_def("talk", &"herb_seller") as TalkDef
		var chat_id: StringName = TalkPicker.pick_chat(talk_def, GameState.flags)
		play(chat_id if not chat_id.is_empty() else &"abu_nabil_chat_1")
	else:
		play(choice.next)


func _clear_choices() -> void:
	_showing_choices = false
	if _choice_list != null:
		_choice_list.clear()


func _slide_portrait_in() -> void:
	var portrait: TextureRect = _layout.portrait
	if _slide != null:
		_slide.kill()
	if not portrait.is_inside_tree():
		return
	var rest: float = _layout.portrait_rest_x
	var shift: float = float(Ui.style().size(&"s_portrait_slide"))
	portrait.modulate.a = 0.0
	portrait.offset_left = rest - shift
	portrait.offset_right = rest - shift + Ui.style().size(&"s_portrait_w")
	var seconds: float = Ui.style().time(&"t_portrait_in")
	_slide = UiMotion.tween(portrait).set_parallel(true)
	_slide.tween_property(portrait, "modulate:a", 1.0, seconds)
	_slide.tween_property(portrait, "offset_left", rest, seconds).set_ease(Tween.EASE_OUT)
	_slide.tween_property(portrait, "offset_right", rest + Ui.style().size(&"s_portrait_w"), seconds).set_ease(Tween.EASE_OUT)
	AudioDirector.play_ui(&"ui_portrait_in")


func _type_all() -> void:
	UiType.finish(_layout.text_label, _typing)
	_typing = null


func _finish() -> void:
	_run = null
	_type_all()
	_clear_choices()
	_set_playing_visuals(false)
	finished.emit(_dialogue_id)


func _set_playing_visuals(playing: bool) -> void:
	visible = playing
