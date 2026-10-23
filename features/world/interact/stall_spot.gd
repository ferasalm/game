class_name StallSpot
extends PillSpot
## The herb stall: stand at the counter and press interact to open the shop screen (Screens id &"shop").

## The player opened the shop (its id).
signal opened(shop_id: StringName)

var shop_id: StringName = &""


func _init(rules: ExploreRulesDef, player: Player, shop: StringName, verb_key: String, lift: float) -> void:
	super(rules, player, verb_key, lift)
	shop_id = shop


func _can_interact() -> bool:
	return _is_near() and not Screens.is_open()


func _interact() -> void:
	opened.emit(shop_id)
	InteractFocus.open_spot(self, shop_id, _player, &"shop", {"shop": shop_id})
