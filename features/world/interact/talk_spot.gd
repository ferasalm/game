class_name TalkSpot
extends PillSpot
## An interact spot for talking to an NPC (e.g. herb_seller): stand nearby and press confirm / interact to talk.

## The player pressed interact at this spot.
signal talked(place_id: StringName)

var place_id: StringName = &""


func _init(rules: ExploreRulesDef, player: Player, place: StringName, verb_key: String, lift: float) -> void:
	super(rules, player, verb_key, lift)
	place_id = place


func _can_interact() -> bool:
	return _is_near() and not Screens.is_open()


func _interact() -> void:
	talked.emit(place_id)
