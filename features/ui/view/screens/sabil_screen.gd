class_name SabilScreen
extends ChoiceScreen
## The sabil fountain question (Screens id &"sabil"): "Drink to rest? This saves your game and restores everyone."
## Closes with &"drink" (default) or &"leave" (Not now, or back). The caller (world) does the saving and the refill,
## then toasts. Use: Screens.open(&"sabil").closed.connect(func(result): ...).

const DRINK: StringName = &"drink"
const LEAVE: StringName = &"leave"


func _init() -> void:
	super()
	layer_id = UiLayers.CONFIRM
	prompts = [{"key": "accept", "text": "PROMPT_SELECT"}, {"key": "back", "text": "SABIL_NOT_NOW"}]


func build(_args: Dictionary) -> void:
	var panel: UiPanel = centred_panel(Ui.text("SABIL_TITLE"), Ui.text("SABIL_TITLE_AR"), Ui.style().size(&"s_confirm_w"))
	var ask: Label = Ui.label(Ui.text("SABIL_ASK"))
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.body.add_child(ask)
	add_choice(panel.body, "SABIL_DRINK", DRINK)
	add_choice(panel.body, "SABIL_NOT_NOW", LEAVE)


func on_back() -> bool:
	choose(LEAVE)
	return true
