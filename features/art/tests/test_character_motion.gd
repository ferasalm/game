extends TestCase
## CharacterVisual motion: the shader material carries the data (minimum light, rim), knocked out / revived snap to
## the right look, the battle motions and the little effects (dust, afterimages, shadow) run without errors, and
## the sprite stays crisp (nearest filtering).


func _visual() -> CharacterVisual:
	var visual := CharacterVisual.new()
	visual.source_kind = &"pixel"
	tree.root.add_child(visual)
	visual.set_sprite(&"zayd")
	return visual


func test_material_reads_the_data() -> void:
	var visual: CharacterVisual = _visual()
	var rules := ContentDB.get_def("visual_rules", &"default") as VisualRulesDef
	check(rules.min_light >= 0.3 and rules.min_light <= 0.5, "a guaranteed 30-50% brightness for the night look")
	check_eq(visual.material.get_shader_parameter(&"min_light"), rules.min_light, "min_light reaches the shader")
	check_eq(visual.material.get_shader_parameter(&"rim_color"), rules.rim_color, "rim colour reaches the shader")
	var texture := visual.material.get_shader_parameter(&"albedo_tex") as Texture2D
	check(texture != null and texture.get_height() == 64, "the 64 px picture is the shader's texture, unscaled")
	check(visual.material.shader.code.contains("filter_nearest"), "nearest filtering keeps the pixels crisp")
	visual.free()


func test_down_and_revive_snap() -> void:
	var visual: CharacterVisual = _visual()
	visual.set_down(true)
	check(visual.is_down(), "down")
	check(is_equal_approx(visual.down_scale.y, visual.rules.down_squash), "collapsed")
	check_eq(visual.material.get_shader_parameter(&"desat"), visual.rules.ko_desat, "drained of colour")
	visual.set_down(false)
	check_eq(visual.down_scale, Vector2.ONE, "back on their feet")
	check_eq(visual.material.get_shader_parameter(&"desat"), 0.0, "colour back")
	visual.free()


func test_battle_motions_start_cleanly() -> void:
	var visual: CharacterVisual = _visual()
	visual.flash()
	visual.hurt(0.3)
	visual.anticipate(Vector3(3.0, 0.0, 0.0))
	visual.dash(Vector3(3.0, 0.0, 0.0))
	visual.cast_pose(0.2)
	visual.victory_hop()
	visual.set_down(true, true)
	visual.set_down(false, true)
	visual.face(-1.0)
	visual.face(1.0)
	check(visual.fx != null, "the effects node exists")
	visual.free()


func test_walk_frame_squashes_and_leans() -> void:
	var visual: CharacterVisual = _visual()
	visual.face(1.0)
	visual.set_moving(true)
	for i: int in 30:
		visual._process(0.016)
	check(visual.body.rotation_degrees.z < 0.0, "leans forward (clockwise) when facing right")
	check(visual.body.scale.y != 1.0, "squash and stretch while walking")
	visual.set_moving(false)
	for i: int in 120:
		visual._process(0.016)
	check(absf(visual.body.rotation_degrees.z) < 0.5, "stands upright again")
	visual.free()


func test_dust_afterimages_and_shadow() -> void:
	var visual: CharacterVisual = _visual()
	visual.fx.puff(Vector3.ZERO, 0.3)
	visual.fx.trail(Vector3.ZERO, Vector3(1.0, 0.0, 0.0), 0.1)
	for i: int in 40:
		visual.fx._process(0.02)
	check(not visual.fx.is_processing(), "the effects go quiet when done")
	visual.fx.sync(Vector3(0.5, 0.0, 0.0), 0.4)
	visual.free()


func test_prop_does_not_breathe() -> void:
	var prop: CharacterVisual = _visual()
	prop.set_prop(true)
	for i: int in 50:
		prop._process(0.05)
	check_eq(prop.body.scale, Vector3.ONE, "a bench stays still")
	prop.free()
