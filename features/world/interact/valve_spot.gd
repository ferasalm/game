class_name ValveSpot
extends InteractSpot
## Interactive valve spot: shows turn prompt and triggers on interact.

var place: PlaceDef


func _init(rules: ExploreRulesDef, player: Player, p: PlaceDef, prompt_y: float) -> void:
	var key: String = String(p.prompt) if p.prompt != &"" else "WORLD_PROMPT_TURN"
	super(rules, player, key, prompt_y)
	place = p


func _interact() -> void:
	print("Valve turned: %s" % (place.id if place != null else &""))
