extends TestCase
## Battle effects: every ActionDef vfx kind has data, every texture paints, the effect player builds and plays each
## kind (single target and all foes) without errors and gives its sprites back to the pool, and the juice numbers
## (hitstop, shake, zoom) come from data and rank heavy above light.


func _stage() -> Dictionary:
	var root := Node3D.new()
	tree.root.add_child(root)
	var vfx := VfxPlayer.new()
	root.add_child(vfx)
	var actor := CharacterVisual.new()
	root.add_child(actor)
	actor.set_sprite(&"zayd")
	actor.position = Vector3(-2.0, 0.0, 0.0)
	var foes: Array[CharacterVisual] = []
	for i: int in 3:
		var foe := CharacterVisual.new()
		root.add_child(foe)
		foe.set_sprite(&"concession_enforcer")
		foe.position = Vector3(1.5 + i, 0.0, 0.0)
		foes.append(foe)
	return {"root": root, "vfx": vfx, "actor": actor, "foes": foes}


func _drain(vfx: VfxPlayer) -> int:
	var steps: int = 0
	while vfx.active_count() > 0 and steps < 200:
		vfx._process(0.05)
		steps += 1
	return steps


func test_every_vfx_kind_has_an_entry() -> void:
	for kind: StringName in ActionDef.VFX_KINDS:
		var def := ContentDB.get_def("vfx", kind) as VfxDef
		check(def != null, "vfx entry for " + kind)
		if def != null:
			check(not def.layers.is_empty(), "%s has layers" % kind)
	check(ContentDB.get_def("vfx", &"break") != null, "the BREAK burst has an entry")


func test_every_texture_paints() -> void:
	for tex: StringName in VfxDef.TEXTURES:
		var image: Image = VfxTextures.texture(tex).get_image()
		var solid: int = 0
		for y: int in image.get_height():
			for x: int in image.get_width():
				if image.get_pixel(x, y).a > 0.0:
					solid += 1
		check(solid > 8, "texture %s has pixels (%d)" % [tex, solid])
		check_eq(Vector2(image.get_size()), VfxTextures.pixels(tex), "size of " + tex)


func test_each_kind_plays_and_ends() -> void:
	var kinds: Array[StringName] = ActionDef.VFX_KINDS.duplicate()
	kinds.append(&"break")
	for kind: StringName in kinds:
		var set: Dictionary = _stage()
		var vfx: VfxPlayer = set["vfx"] as VfxPlayer
		var foes: Array[CharacterVisual] = set["foes"] as Array[CharacterVisual]
		vfx.play(ContentDB.get_def("vfx", kind) as VfxDef, set["actor"] as CharacterVisual, foes)
		check(vfx.active_count() > 0, kind + " spawns sprites")
		var steps: int = _drain(vfx)
		check(steps < 200 and vfx.active_count() == 0, kind + " ends and frees its sprites")
		(set["root"] as Node3D).free()


func test_the_pool_is_reused() -> void:
	var set: Dictionary = _stage()
	var vfx: VfxPlayer = set["vfx"] as VfxPlayer
	var def := ContentDB.get_def("vfx", &"arc_all") as VfxDef
	var foes: Array[CharacterVisual] = set["foes"] as Array[CharacterVisual]
	vfx.play(def, set["actor"] as CharacterVisual, foes)
	_drain(vfx)
	var grown: int = vfx.pool_size()
	vfx.play(def, set["actor"] as CharacterVisual, foes)
	_drain(vfx)
	check_eq(vfx.pool_size(), grown, "a second identical effect allocates no new sprites")
	vfx.play(def, null, foes)
	check_eq(vfx.active_count(), 0, "no actor, no effect")
	(set["root"] as Node3D).free()


func test_chain_visits_every_target() -> void:
	var set: Dictionary = _stage()
	var vfx: VfxPlayer = set["vfx"] as VfxPlayer
	var one: Array[CharacterVisual] = [(set["foes"] as Array[CharacterVisual])[0]]
	var def := ContentDB.get_def("vfx", &"arc_all") as VfxDef
	vfx.play(def, set["actor"] as CharacterVisual, one)
	var single: int = vfx.active_count()
	_drain(vfx)
	vfx.play(def, set["actor"] as CharacterVisual, set["foes"] as Array[CharacterVisual])
	check(vfx.active_count() > single, "three targets paint more bolts than one")
	(set["root"] as Node3D).free()


func test_juice_numbers_come_from_data() -> void:
	var juice := ContentDB.get_def("battle_juice", &"default") as JuiceDef
	check(juice != null and juice.freeze_scale < 0.5, "a hitstop freezes time")
	var light := ContentDB.get_def("vfx", &"slash") as VfxDef
	var heavy := ContentDB.get_def("vfx", &"heavy_slash") as VfxDef
	check(heavy.hitstop > light.hitstop, "heavy hits freeze longer")
	check(heavy.shake > light.shake and heavy.zoom > light.zoom, "heavy hits shake and push in more")
	check(juice.break_hitstop > light.hitstop, "a cut cast freezes longer than a light hit")
	check(ContentDB.get_def("vfx", &"heal").hitstop == 0.0, "support moves do not freeze")


func test_hitstop_freezes_and_restores_time() -> void:
	var node := BattleJuice.new()
	tree.root.add_child(node)
	node.setup(ContentDB.get_def("battle_juice", &"default") as JuiceDef, null)
	node.hitstop(0.5)
	check(node.is_frozen(), "frozen while the timer runs")
	check_eq(Engine.time_scale, node.def.freeze_scale, "time scale from data")
	node.free()
	check_eq(Engine.time_scale, 1.0, "leaving the tree restores time")
	node = BattleJuice.new()
	node.setup(ContentDB.get_def("battle_juice", &"default") as JuiceDef, null)
	node.hitstop(0.5)
	check_eq(Engine.time_scale, 1.0, "no tree, no freeze")
	node.free()


func test_targets_of_a_move() -> void:
	var events: Array[TimelineEvent] = [
		TimelineEvent.new(&"act", &"zayd", 100), TimelineEvent.new(&"damage", &"e1", 10, &"x"),
		TimelineEvent.new(&"knocked_back", &"e1", 5), TimelineEvent.new(&"damage", &"e2", 10, &"x"),
		TimelineEvent.new(&"status", &"e2", 2, &"net"), TimelineEvent.new(&"healed", &"zayd", 3, &"regen"),
		TimelineEvent.new(&"act", &"e1", 100), TimelineEvent.new(&"damage", &"zayd", 4, &"y")]
	var player := BattleEventPlayer.new()
	check_eq(player._targets_after(events, 0), [&"e1", &"e2"] as Array[StringName], "damage and status name the targets once")
	check_eq(player._targets_after(events, 6), [&"zayd"] as Array[StringName], "the next move has its own")
	player.free()
