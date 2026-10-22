extends Node
## Renders the battle HUD to PNG files (not headless; needs a window). Run:
## "$(tools/godot.sh)" --path . --resolution 1920x1080 -s res://tools/shot_scene.gd -- res://tools/shot_hud.gd <out dir> <scenario>
## scenarios: rest (a moment of the fight with no menu), turn (a hero waits), target (the enemy picker is open).

const REST_FRAME: int = 12
const TURN_FRAME: int = 400
const PICK_FRAME: int = 420
const TARGET_FRAME: int = 450
var _stage: BattleStage
var _frame: int = 0
var _dir: String = "inbox/hud_v3"
var _scenario: String = "turn"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_dir = args[1] if args.size() > 1 else _dir
	_scenario = args[2] if args.size() > 2 else _scenario
	var look := ContentDB.get_def("look", &"night") as LookDef
	add_child(Diorama.make_environment(look))
	add_child(Diorama.make_sun(look))
	var floor_block := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(24.0, 0.5, 24.0)
	floor_block.mesh = mesh
	floor_block.material_override = Diorama.material(Color(0.78, 0.7, 0.55))
	floor_block.position = Vector3(0.0, -0.25, 0.0)
	add_child(floor_block)
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	_stage = BattleStage.new()
	add_child(_stage)
	_stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7), Vector3.ZERO)


func _process(_delta: float) -> void:
	_frame += 1
	if _scenario == "rest" and _frame == REST_FRAME:
		_save()
		return
	if _scenario == "turn" and _frame == TURN_FRAME:
		_save()
		return
	if _scenario == "target" and _frame == PICK_FRAME and _stage.hud.menu.is_open():
		_stage.hud.menu.move_buttons()[0].pressed.emit()
	if _scenario == "target" and _frame == TARGET_FRAME:
		_save()
		return


func _save() -> void:
	var image: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_dir)
	image.save_png("%s/%s.png" % [_dir, _scenario])
	print("saved ", _scenario, " menu_open=", _stage.hud.menu.is_open(), " frame=", _frame)
	for button: Button in _stage.hud.menu.move_buttons():
		print("button ", button.size, " min ", button.get_combined_minimum_size())
	print("panel ", _stage.hud.turn_panel.size, " card ", _stage.hud.turn_panel.card.size, " menu ", _stage.hud.menu.size)
	print("viewport ", get_viewport().get_visible_rect(), " rects ", _stage.hud.fighter_rects)
	get_tree().quit()
