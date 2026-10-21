class_name BattleEnding
extends RefCounted
## How a fight leaves the screen. A defeat opens the Defeat screen (Retry fight, Load last save, Title) over the
## arena. Leaving by victory or by a plain defeat sweeps qamariya glass over everything (Ui.transition_sweep) and
## hands over when the glass covers the screen, so the area is shown again underneath as the glass lifts. The glass
## lives under the scene root, not the stage, so it outlives the stage the hand-over frees.

const WASH_RESULTS: Array[StringName] = [&"victory", &"defeat"]


## Opens the Defeat screen and calls on_choice(&"retry" | &"load" | &"title") when it closes with a pick.
## False when no screen could open (the caller falls back to the end panel).
static func open_defeat(on_choice: Callable) -> bool:
	var screen: UiScreen = Screens.open(Screens.DEFEAT_ID)
	if screen == null:
		return false
	screen.closed.connect(_on_defeat_closed.bind(on_choice))
	return true


## True when leaving with this result plays the light wash.
static func washes(result: StringName) -> bool:
	return WASH_RESULTS.has(result)


## Sweeps the glass over the screen; at_cover runs once it is fully covered. The layer frees itself afterwards.
static func wash(host: Node, at_cover: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = UiLayers.TRANSITION
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var root: Control = Ui.screen_root()
	layer.add_child(root)
	host.get_tree().root.add_child(layer)
	var tween: Tween = Ui.transition_sweep(root, at_cover)
	tween.finished.connect(layer.queue_free)


static func _on_defeat_closed(result: Variant, on_choice: Callable) -> void:
	if result != null:  # null: the screen was cleared because the flow left the fight
		on_choice.call(StringName(str(result)))
