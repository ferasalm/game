class_name SabilSpot
extends PillSpot
## The sabil fountain: interact opens the "Drink to rest?" screen. Drinking saves (slot 1), refills the party and
## brings the patrols back (SabilDrink); this node then announces `drunk` so the rooftop resets its patrols.

## The player drank and the game was saved.
signal drunk
## The player pressed interact at the sabil fountain.
signal opened

const SAVE_SLOT: int = 1

var place_id: StringName = &""


func _init(rules: ExploreRulesDef, player: Player, place: StringName, verb_key: String, lift: float) -> void:
	super(rules, player, verb_key, lift)
	place_id = place


func _can_interact() -> bool:
	return _is_near() and not Screens.is_open()


func _interact() -> void:
	opened.emit()
	if not GameState.flags.get(&"party_sabil_first_done", false):
		return
	open_screen()


func open_screen() -> void:
	var screen: UiScreen = Screens.open(Screens.SABIL_ID)
	if screen != null:
		screen.closed.connect(_on_closed)


## What the screen's answer does: &"drink" runs the drink, anything else nothing.
func _on_closed(result: Variant) -> void:
	if result == SabilScreen.DRINK:
		drink()


## The drink itself (public so tests can call it): toasts the outcome, returns true when saved.
func drink() -> bool:
	var problem: String = SabilDrink.apply(place_id, SAVE_SLOT)
	if not problem.is_empty():
		Ui.toast("SABIL_FAIL", &"bad")
		return false
	Ui.toast("SABIL_SAVED", &"good")
	Ui.toast("SABIL_PATROLS")
	drunk.emit()
	return true
