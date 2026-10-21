extends TestCase
## Painted diorama look spike: the three painted looks read and differ, their camera presets put the camera at
## the preset pitch, world materials switch to the painted shader only while a painted look is in use, the baked
## textures load (and fall back when missing), every bake matches the current painter inputs (re-bake when this
## fails), the grade LUT is the identity at amount 0, and a painted rooftop gets its outline, screen pass and figure.

const LOOKS: Array[StringName] = [&"painted_a", &"painted_b", &"painted_c"]


func _look(look_id: StringName) -> LookDef:
	return ContentDB.get_def("look", look_id) as LookDef


func _rig() -> CameraRigDef:
	return ContentDB.get_def("camera_rig", &"explore") as CameraRigDef


func test_painted_looks_read_and_differ() -> void:
	check(_look(&"night").paint == null, "the night look stays unpainted")
	var seen: Dictionary = {}
	for look_id: StringName in LOOKS:
		var look: LookDef = _look(look_id)
		check(look != null and look.paint != null, "%s is a painted look" % look_id)
		check(_rig().presets.has(look.camera_preset), "%s names a camera preset of the explore rig" % look_id)
		seen["%s:%s:%s" % [look.camera_preset, look.paint.bake, look.paint.outline_width]] = true
	check_eq(seen.size(), LOOKS.size(), "each variant has its own camera, bake and outline")


func test_camera_preset_pitch_and_follow() -> void:
	var rig: CameraRigDef = _rig()
	for preset_id: StringName in rig.presets:
		var pose: CameraRigDef.Preset = rig.presets[preset_id]
		var above: Vector3 = pose.offset - Vector3(0.0, pose.look_height, 0.0)
		check(above.y > 0.0 and above.z > 0.0, "%s looks down from the south" % preset_id)
		check(pose.dof_near < above.length() and above.length() < pose.dof_far, "%s focuses on the player" % preset_id)
	var hades: CameraRigDef.Preset = rig.presets[&"hades"]
	var pitch: float = rad_to_deg(atan2(hades.offset.y - hades.look_height, hades.offset.z))
	check(absf(pitch - 55.0) < 0.01, "the hades preset looks down 55 degrees")
	check_eq(rig.pose_for(_look(&"night")).offset, _look(&"night").camera_offset, "no preset: the look's own offset")


func test_materials_switch_only_while_painted() -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	PaintedMaterials.use(_look(&"painted_a").paint)
	var painted: Material = SurfaceMaterials.tile(&"brick", palette)
	check(painted is ShaderMaterial, "a painted look gives the painted world shader")
	check_eq((painted as ShaderMaterial).get_shader_parameter(&"paint_mix"), 1.0, "with the painted light on")
	check(SurfaceMaterials.trim() is ShaderMaterial, "trim is painted too")
	PaintedMaterials.use(null)
	check(SurfaceMaterials.tile(&"brick", palette) is StandardMaterial3D, "unpainted: the old material again")
	check(Diorama.material(Color.RED) is StandardMaterial3D, "unpainted flat colour")


func test_baked_textures_load_and_fall_back() -> void:
	for bake: StringName in [&"wash", &"oil"]:
		var image: Image = PaintedMaterials.load_baked(bake, "tile_brick")
		check(image != null and image.get_width() > SurfacePainter.SIZE, "%s bake of tile_brick loads, upscaled" % bake)
	check(PaintedMaterials.load_baked(&"oil", "no_such_atlas") == null, "a missing bake is null")
	var fallback := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	PaintedMaterials.use(_look(&"painted_b").paint)
	check_eq(PaintedMaterials.texture("no_such_atlas", fallback).get_width(), 8, "missing bake: the unbaked atlas")
	PaintedMaterials.use(null)


func test_bakes_match_painter_inputs() -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var atlases: Dictionary[String, Image] = PaintedAtlases.all(palette)
	for bake: StringName in [&"wash", &"oil"]:
		var inputs: Dictionary = PaintedAtlases.baked_inputs(bake)
		for atlas_id: String in atlases:
			check_eq(inputs.get(atlas_id, ""), PaintedAtlases.digest(atlases[atlas_id]),
				"%s/%s was baked from today's painter output (re-run tools/export_atlases.gd + painterly_bake.py)"
				% [bake, atlas_id])


func test_lut_identity_and_split_tone() -> void:
	var paint := PaintDef.new()
	paint.lut_amount = 0.0
	var grey := Color(0.5, 0.5, 0.5)
	check(PaintedLook.split_tone(grey, paint).is_equal_approx(grey), "amount 0 changes nothing")
	paint.lut_amount = 1.0
	paint.lut_shadows = Color("#3d3a73")
	var dark: Color = PaintedLook.split_tone(Color(0.2, 0.2, 0.2), paint)
	check(dark.b > dark.r, "shadows lean toward the indigo shadow tone")
	check_eq(PaintedLook.make_lut(paint).get_depth(), PaintedLook.LUT_SIZE, "a full 3D LUT")


func test_painted_rooftop_builds() -> void:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	rooftop.look_id = &"painted_c"
	tree.root.add_child(rooftop)
	var outline: bool = false
	for child: Node in rooftop.camera.get_children():
		outline = outline or (child is MeshInstance3D and (child as MeshInstance3D).material_override is ShaderMaterial)
	check(outline, "the ink outline quad rides on the camera")
	var figure: bool = false
	for child: Node in rooftop.player.get_children():
		figure = figure or child is PaintedFigure
		if child is CharacterVisual:
			check(not (child as CharacterVisual).visible, "the pixel sprite is hidden behind the painted figure")
	check(figure, "Zayd is the painted figure")
	rooftop.free()
	PaintedMaterials.use(null)
	tree.root.get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
