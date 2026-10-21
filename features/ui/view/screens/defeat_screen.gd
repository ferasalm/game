class_name DefeatScreen
extends ChoiceScreen
## The defeat screen (Screens id &"defeat"): the arena darkens over t_defeat_fade, then DEFEATED offers Retry fight
## (default), Load last save (greyed with no save) and Title (asks first). It closes with &"retry", &"load" or
## &"title"; back is ignored (no way out without choosing). The caller (battle) acts on the result.

const RETRY: StringName = &"retry"
const LOAD: StringName = &"load"
const TITLE: StringName = &"title"

var _panel: UiPanel


func _init() -> void:
	super()
	prompts = [{"key": "accept", "text": "PROMPT_SELECT"}]


func build(_args: Dictionary) -> void:
	var style: UiStyleDef = Ui.style()
	var dark := ColorRect.new()
	dark.color = style.colour(&"c_scrim")
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)
	_panel = centred_panel(Ui.text("DEFEAT_TITLE"), Ui.text("DEFEAT_TITLE_AR"), style.size(&"s_defeat_w"),
			style.size(&"s_defeat_h"))
	add_choice(_panel.body, "DEFEAT_RETRY", RETRY)
	add_choice(_panel.body, "DEFEAT_LOAD", LOAD, Router.has_save(1))
	add_choice(_panel.body, "DEFEAT_TITLE_MENU", TITLE)
	dark.modulate.a = 0.0
	_panel.modulate.a = 0.0
	var fade: Tween = UiMotion.tween(self)
	fade.tween_property(dark, "modulate:a", 1.0, style.time(&"t_defeat_fade"))
	fade.tween_property(_panel, "modulate:a", 1.0, style.time(&"t_screen_in"))


## Title asks first; the other two answer at once.
func choose(result: StringName) -> void:
	if result == TITLE:
		if await Ui.confirm("DEFEAT_TITLE_MENU", "PAUSE_CONFIRM_TITLE", false):
			super(result)
		return
	super(result)


## Back does nothing here.
func on_back() -> bool:
	return true
