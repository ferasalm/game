class_name SabilSpot
extends PillSpot
## The sabil fountain: interact opens the "Drink to rest?" screen. Drinking saves (slot 1), refills the party and
## brings the patrols back (SabilDrink); this node then announces `drunk` so the rooftop resets its patrols.

## The player drank and the game was saved.
signal drunk
## The player pressed interact at the sabil fountain.
signal opened

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


## What the screen's answer does: &"drink" opens the slot picker in Save mode.
func _on_closed(result: Variant) -> void:
	if result == SabilScreen.DRINK:
		var picker := Screens.open(Screens.SLOT_PICKER_ID, {"mode": SlotPickerScreen.MODE_SAVE}) as SlotPickerScreen
		if picker != null:
			picker.closed.connect(_on_picker_closed)


func _on_picker_closed(result: Variant) -> void:
	var slot: int = int(result) if result != null else 0
	if slot > 0:
		drink(slot)


## The drink itself (public so tests can call it): toasts the outcome, returns true when saved.
func drink(slot: int = 1) -> bool:
	var problem: String = SabilDrink.apply(place_id, slot)
	if not problem.is_empty():
		Ui.toast("SABIL_FAIL", &"bad")
		return false
	Ui.toast("SABIL_SAVED", &"good")
	Ui.toast("SABIL_PATROLS")
	drunk.emit()
	return true
