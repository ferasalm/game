extends Node
## Builds one battle arena on its own (no rooftop, no Router): the BattleRunner with the default encounter, heroes on
## auto-play, the HUD hidden when the user argument "hud=off" is given, so the painted arena can be judged alone.
## Run (not headless): "$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60 --quit-after N
## -s res://tools/shot_scene.gd -- res://tools/shot_arena.gd [look=painted_b] [hud=off]

var _runner: BattleRunner
var _hud_off: bool = false


func _ready() -> void:
	var request := BattleRequest.new()
	request.encounter_id = &"rooftop_patrol"
	request.arena_id = &"rooftop_arena"
	request.party = [&"zayd", &"bilqis"]
	_hud_off = "hud=off" in OS.get_cmdline_user_args()
	_runner = BattleRunner.new()
	add_child(_runner)
	_runner.stage_created.connect(func(stage: BattleStage) -> void: stage.auto_play = true)
	_runner.begin(request)


func _process(_delta: float) -> void:
	if _hud_off and _runner.stage != null and _runner.stage.hud != null:
		_runner.stage.hud.visible = false
