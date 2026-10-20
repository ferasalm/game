extends Node3D
## Battle view demo: a plain floor in the accepted HD-2D look and a BattleStage fighting the rooftop patrol
## (swift hilt, keen blade, seed 7, ambushed so the reverse stab shows). Press F6 on this scene. When the battle
## ends the scene restarts. Tick auto_play in the inspector to watch the heroes play themselves.

const LOOK_ID: StringName = &"v1"
const FLOOR_SIZE: Vector3 = Vector3(24.0, 0.5, 24.0)
const FLOOR_COLOR: Color = Color(0.78, 0.7, 0.55)
const HILT: StringName = &"swift_hilt"
const BLADE: StringName = &"keen_blade"
const BATTLE_SEED: int = 7
const AMBUSH_PARTY: int = 1

@export var auto_play: bool = false


func _ready() -> void:
	var look := ContentDB.get_def("look", LOOK_ID) as LookDef
	if look == null:
		look = LookDef.new()
	add_child(Diorama.make_environment(look))
	add_child(Diorama.make_sun(look))
	_add_floor()
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.auto_play = auto_play
	add_child(stage)
	stage.ended.connect(_on_ended)
	stage.start(loader.make_sim(HILT, BLADE, BATTLE_SEED, AMBUSH_PARTY), Vector3.ZERO)


func _add_floor() -> void:
	var floor_block := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = FLOOR_SIZE
	floor_block.mesh = mesh
	floor_block.material_override = Diorama.material(FLOOR_COLOR)
	floor_block.position = Vector3(0.0, -FLOOR_SIZE.y / 2.0, 0.0)
	add_child(floor_block)


func _on_ended(_result: StringName) -> void:
	get_tree().reload_current_scene.call_deferred()
