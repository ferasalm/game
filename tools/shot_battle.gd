extends Node
## Starts the prototype and, after a moment of walking, makes the patrol touch the player so the battle (camera
## swoop, effects) can be filmed with the movie writer. Heroes play themselves. Run (not headless):
## "$(tools/godot.sh)" --path . --resolution 960x540 --write-movie DIR/f.png --fixed-fps 30 --quit-after N
## -s res://tools/shot_scene.gd -- res://tools/shot_battle.gd

const START_AFTER: float = 1.0
const PATROL_GAP: Vector3 = Vector3(2.2, 0.0, 0.0)

var _main: PrototypeMain
var _clock: float = 0.0
var _started: bool = false


func _ready() -> void:
	_main = (load("res://features/prototype/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
	add_child(_main)
	_main.stage_created.connect(func(stage: BattleStage) -> void: stage.auto_play = true)


func _process(delta: float) -> void:
	_clock += delta
	if _started or _clock < START_AFTER:
		return
	_started = true
	_main.rooftop.camera_rig.skip_intro(true)
	_main.rooftop.patrol.position = _main.rooftop.player.position + PATROL_GAP
	_main.rooftop._on_touched(false)
