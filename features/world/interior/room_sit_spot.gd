class_name RoomSitSpot
extends InteractSpot
## purpose: Interactive sit spot at a majlis cushion. Emits sat(spot_id) on interact.

signal sat(spot_id: StringName)

var spot_id: StringName = &""


func _init(rules: ExploreRulesDef, player: Player, id: StringName) -> void:
	super(rules, player, "WORLD_PROMPT_SIT", rules.prompt_height)
	spot_id = id


func _interact() -> void:
	sat.emit(spot_id)
