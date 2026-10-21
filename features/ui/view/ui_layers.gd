class_name UiLayers
extends RefCounted
## The one table of CanvasLayer layers (engine draw-order values, so named constants are allowed here). Every screen,
## HUD and popup takes its layer from here; a higher number draws over a lower one.

const HUD: int = 5
const DIALOGUE: int = 8
const PAUSE: int = 9  ## under SCREEN: Items and Equipment open over the pause menu
const SCREEN: int = 10
const CONFIRM: int = 14
const LOOT: int = 20
const CARD: int = 25
const TITLE: int = 30
const TOAST: int = 35
const TRANSITION: int = 40


## Every layer in drawing order, lowest first (a test keeps them strictly increasing).
static func ordered() -> Array[int]:
	return [HUD, DIALOGUE, PAUSE, SCREEN, CONFIRM, LOOT, CARD, TITLE, TOAST, TRANSITION]
