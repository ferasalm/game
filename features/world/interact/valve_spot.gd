class_name ValveSpot
extends InteractSpot
## Interactive valve spot: shows turn prompt and hands the key press to the valve's puzzle board.

var place: PlaceDef
var board: PuzzleBoard


func _init(rules: ExploreRulesDef, player: Player, p: PlaceDef, prompt_y: float) -> void:
	var key: String = String(p.prompt) if p.prompt != &"" else "WORLD_PROMPT_TURN"
	super(rules, player, key, prompt_y)
	place = p


func set_puzzle(p_board: PuzzleBoard) -> void:
	board = p_board


func _interact() -> void:
	if board != null:
		board.interact()
