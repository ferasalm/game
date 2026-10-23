extends Node
## purpose: Renders pause, save, shop, or equipment menu at 1920x1080 to an inbox PNG.
## Run: tools/run_godot.sh res://tools/shot_menu.tscn -- <menu_kind>

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
	_build_screen()


func _build_screen() -> void:
	match _menu_kind:
		"pause", "fix_pause":
			_setup_pause()
		"save":
			_setup_save()
		"shop":
			_screen = ShopScreen.new()
			_sub_vp.add_child(_screen)
			_screen.open({"shop": &"herb_stall"})
		"equipment", "fix_equip_zayd":
			_setup_equipment(&"zayd")
		"fix_equip_bilqis":
			_setup_equipment(&"bilqis")
		"workshop_upgrade", "workshop_gemstones", "workshop_crafting":
			_setup_workshop()


func _setup_pause() -> void:
	GameState.start_new()
	_screen = PauseMenu.new()
	_sub_vp.add_child(_screen)
	_screen.open()


func _setup_save() -> void:
	var service := SaveService.new("user://saves")
	service.write(1, {"version": 4, "money": 12450, "play_seconds": 5047.0, "place": {"area": "souq_rooftops"}})
	var thumb := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	thumb.fill(Color(0.2, 0.3, 0.4))
	service.write_thumbnail(1, thumb)
	_screen = SlotPickerScreen.new()
	_sub_vp.add_child(_screen)
	_screen.open({"mode": SlotPickerScreen.MODE_SAVE})


func _setup_equipment(hero_name: StringName = &"zayd") -> void:
	GameState.start_new()
	var items: Array[StringName] = [
		&"swift_hilt", &"keen_blade", &"arc_arm", &"concession_plate", &"mesh_abaya",
		&"sulaimani", &"fayruz", &"jaz_black", &"aqiq_red"
	]
	for item_id: StringName in items:
		Inventory.add(GameState.inventory, item_id)
	_screen = EquipmentMenu.new()
	_sub_vp.add_child(_screen)
	_screen.open()
	(_screen as EquipmentMenu).show_hero(hero_name)


func _setup_workshop() -> void:
	GameState.start_new()
	GameState.money = 8450
	GameState.materials[&"scrap_copper"] = 4
	GameState.materials[&"drone_coil"] = 2
	GameState.materials[&"salt_crystal"] = 1
	var items: Array[StringName] = [
		&"swift_hilt", &"keen_blade", &"anvil_hilt", &"broad_blade",
		&"concession_plate", &"mesh_abaya", &"sulaimani", &"fayruz", &"jaz_black"
	]
	for item_id: StringName in items:
		Inventory.add(GameState.inventory, item_id)
	_screen = WorkshopMenu.new()
	_sub_vp.add_child(_screen)
	_screen.open()
	var tab_idx: int = WorkshopTabsBar.Tab.UPGRADE
	if _menu_kind == "workshop_gemstones":
		tab_idx = WorkshopTabsBar.Tab.GEMSTONES
	elif _menu_kind == "workshop_crafting":
		tab_idx = WorkshopTabsBar.Tab.CRAFTING
	(_screen as WorkshopMenu)._tabs.select_tab(tab_idx)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame >= SETTLE_FRAMES:
		var img: Image = _sub_vp.get_texture().get_image()
		var file_name: String = "%s.png" % _menu_kind if _menu_kind.begins_with("fix_") else "menu_%s.png" % _menu_kind
		var out_path: String = OUT_DIR.path_join(file_name)
		img.save_png(out_path)
		print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
		get_tree().quit()
