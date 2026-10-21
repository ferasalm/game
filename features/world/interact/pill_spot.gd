class_name PillSpot
extends InteractSpot
## An interact spot whose prompt is the UI's glass pill ("[E] Verb", Ui.interaction_prompt) instead of a 3D label:
## the pill follows the spot through the camera and shows while the player is in range. The stall and the sabil.

var _pill: InteractionPrompt
var _layer: CanvasLayer


## verb_key: a localization key ("PROMPT_TALK"); lift: metres above the spot where the pill floats.
func _init(rules: ExploreRulesDef, player: Player, verb_key: String, lift: float) -> void:
	super(rules, player, "", lift)
	_pill = Ui.interaction_prompt(verb_key)
	_pill.bind_world(self, player, lift)
	_pill.visible = false


func _ready() -> void:
	super()
	_layer = CanvasLayer.new()
	_layer.layer = UiLayers.HUD
	add_child(_layer)
	_layer.add_child(_pill)


func pill() -> InteractionPrompt:
	return _pill


func _show_prompt(on: bool) -> void:
	if _pill != null:
		_pill.visible = on
