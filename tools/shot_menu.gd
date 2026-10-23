extends Node
## Renders pause, save, or shop menu at 1920x1080 to an inbox PNG.
## Run: "$(tools/godot.sh)" --path . --resolution 1920x1080 res://tools/shot_menu.tscn -- <menu_kind>

const OUT_DIR: String = "C:/dev/game/inbox"
const SETTLE_FRAMES: int = 15

var _menu_kind: String = "pause"
var _frame: int = 0
var _sub_vp: SubViewport
var _screen: UiScreen


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_menu_kind = args[0]

	_sub_vp = SubViewport.new()
	_sub_vp.size = Vector2i(1920, 1080)
	_sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub_vp)

	Router.save_dir = "user://saves"
	match _menu_kind:
		"pause":
			_screen = PauseMenu.new()
			_sub_vp.add_child(_screen)
			_screen.open()
		"save":
			var service := SaveService.new("user://saves")
			service.write(1, {"version": 4, "money": 12450, "play_seconds": 5047.0, "place": {"area": "souq_rooftops"}})
			var thumb := Image.create(480, 270, false, Image.FORMAT_RGBA8)
			thumb.fill(Color(0.2, 0.3, 0.4))
			service.write_thumbnail(1, thumb)
			_screen = SlotPickerScreen.new()
			_sub_vp.add_child(_screen)
			_screen.open({"mode": SlotPickerScreen.MODE_SAVE})
		"shop":
			_screen = ShopScreen.new()
			_sub_vp.add_child(_screen)
			_screen.open({"shop": &"herb_stall"})
		"equipment":
			GameState.start_new()
			for item_id: StringName in [&"swift_hilt", &"keen_blade", &"arc_arm", &"concession_plate", &"mesh_abaya"]:
				Inventory.add(GameState.inventory, item_id)
			_screen = EquipmentMenu.new()
			_sub_vp.add_child(_screen)
			_screen.open()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame >= SETTLE_FRAMES:
		var img: Image = _sub_vp.get_texture().get_image()
		var out_path: String = OUT_DIR.path_join("menu_%s.png" % _menu_kind)
		img.save_png(out_path)
		print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
		get_tree().quit()
