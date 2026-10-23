class_name DoorSpot
extends InteractSpot
## Interactive door spot: shows enter prompt and logs transition on interact.

signal entered(target: StringName)

var place: PlaceDef


func _init(rules: ExploreRulesDef, player: Player, p: PlaceDef, prompt_y: float) -> void:
	var key: String = String(p.prompt) if p.prompt != &"" else "WORLD_PROMPT_ENTER"
	super(rules, player, key, prompt_y)
	place = p


func _interact() -> void:
	entered.emit(place.target if place != null else &"")

