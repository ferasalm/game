extends TestCase
## The data behind live 3D characters (content/art/models.json, clips.json) against the imported assets: every model
## maps all nine states to clips that exist, every clip names a real animation of the shared library with its length and
## an impact inside it, the bodies keep the rig's bone names, every anchor and part bone resolves, and the budgets hold
## (bones, triangles, surfaces, textures). The stand-in bodies are 14.3k and 15.06k triangles: the hero budget, so
## the enemy and NPC budgets of docs/design/characters-3d.md 6 wait for Feras's own models.

const MAX_BONES: int = 70
const MAX_TRIS: int = 15100
const MAX_SCREEN_TRIS: int = 90000
const MAX_BODY_MATERIALS: int = 3
const MAX_TEXTURE: int = 1024


func _models(kind: StringName) -> Array[ModelDef]:
	var out: Array[ModelDef] = []
	for id: StringName in ContentDB.ids("model"):
		var def := ContentDB.get_def("model", id) as ModelDef
		if def.kind == kind:
			out.append(def)
	return out


func test_every_model_maps_all_nine_states_to_existing_clips() -> void:
	check(ContentDB.ids("model").size() >= 5, "zayd, bilqis, abu_nabil, enforcer and drone are models")
	for id: StringName in ContentDB.ids("model"):
		var def := ContentDB.get_def("model", id) as ModelDef
		for state: StringName in CharacterVisual.STATES:
			var clip_id: String = def.states.get(String(state), "")
			check(ContentDB.get_def("clip", StringName(clip_id)) != null, "%s: state %s -> clip '%s' exists" % [id, state, clip_id])


func test_every_clip_matches_its_animation() -> void:
	var library: AnimationLibrary = ModelRig.library()
	check(library != null, "the animation library loads")
	for id: StringName in ContentDB.ids("clip"):
		var clip := ContentDB.get_def("clip", id) as ClipDef
		if clip.animation.is_empty():
			continue
		check(library.has_animation(clip.animation), "%s: animation %s exists" % [id, clip.animation])
		if library.has_animation(clip.animation):
			var length: float = library.get_animation(clip.animation).length
			check(absf(length - clip.seconds) < 0.01, "%s: seconds %s match the animation's %s" % [id, clip.seconds, length])
		check(clip.impact_t <= clip.seconds and clip.strike_end_t <= clip.seconds, "%s: impact inside the clip" % id)


func test_impacts_come_after_the_windup_and_before_the_end() -> void:
	for id: StringName in ContentDB.ids("clip"):
		var clip := ContentDB.get_def("clip", id) as ClipDef
		if clip.impact_t < 0.0:
			continue
		var hit: float = ClipTiming.real_at(clip, clip.impact_t)
		check(hit >= 0.0 and hit <= ClipTiming.total(clip), "%s: impact lies inside the clip's real time" % id)


func test_the_bodies_keep_the_rig_and_the_budgets() -> void:
	var triangles_by_scene: Dictionary[String, int] = {}
	for def: ModelDef in _models(&"skinned"):
		var holder := Node3D.new()
		tree.root.add_child(holder)
		var rig := ModelRig.new()
		check(rig.build(def, holder), "%s builds" % def.id)
		check(rig.skeleton.get_bone_count() <= MAX_BONES, "%s: at most %d bones" % [def.id, MAX_BONES])
		var tris: int = 0
		var surfaces: int = 0
		for mesh: Node in rig.skeleton.get_children():
			var instance := mesh as MeshInstance3D
			if instance == null:
				continue
			surfaces += instance.mesh.get_surface_count()
			for s: int in instance.mesh.get_surface_count():
				tris += (instance.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		check(tris <= MAX_TRIS, "%s: %d triangles within %d" % [def.id, tris, MAX_TRIS])
		check(surfaces <= MAX_BODY_MATERIALS, "%s: %d body surfaces within %d" % [def.id, surfaces, MAX_BODY_MATERIALS])
		triangles_by_scene[def.id] = tris
		for bone: String in def.anchors.values():
			check(rig.skeleton.find_bone(bone) >= 0, "%s: anchor bone %s exists" % [def.id, bone])
		for part: ModelPartDef in def.parts:
			check(rig.skeleton.find_bone(part.bone) >= 0, "%s/%s: bone %s exists" % [def.id, part.id, part.bone])
			check(part.to_bone.is_empty() or rig.skeleton.find_bone(part.to_bone) >= 0, "%s/%s: to_bone exists" % [def.id, part.id])
			check(part.draw_bone.is_empty() or rig.skeleton.find_bone(part.draw_bone) >= 0, "%s/%s: draw_bone exists" % [def.id, part.id])
			check(rig.parts.has(part.id), "%s: part %s was built" % [def.id, part.id])
		for path: String in [def.skin, def.eye_texture, def.hair_texture]:
			var texture := load(path) as Texture2D
			check(texture != null and maxi(texture.get_width(), texture.get_height()) <= MAX_TEXTURE, "%s: texture %s within %d" % [def.id, path.get_file(), MAX_TEXTURE])
		holder.free()
	var party: int = 0
	for id: StringName in [&"zayd", &"bilqis", &"abu_nabil", &"concession_enforcer", &"concession_enforcer"]:
		party += triangles_by_scene.get(id, 0)
	check(party <= MAX_SCREEN_TRIS, "five characters on screen stay within %d triangles (%d)" % [MAX_SCREEN_TRIS, party])


func test_the_bodies_share_the_animation_rig() -> void:
	var library: AnimationLibrary = ModelRig.library()
	var anim: Animation = library.get_animation("Walk")
	for def: ModelDef in _models(&"skinned"):
		var holder := Node3D.new()
		tree.root.add_child(holder)
		var rig := ModelRig.new()
		rig.build(def, holder)
		var missing: int = 0
		for track: int in anim.get_track_count():
			var path: NodePath = anim.track_get_path(track)
			if rig.model.get_path_to(rig.skeleton) != NodePath(str(path).get_slice(":", 0)):
				missing += 1
			elif rig.skeleton.find_bone(path.get_subname(0)) < 0:
				missing += 1
		check_eq(missing, 0, "%s: every Walk track finds its bone (no retargeting needed)" % def.id)
		holder.free()


func test_zayd_wears_his_grandfathers_hilt_and_every_model_has_a_height() -> void:
	var zayd := ContentDB.get_def("model", &"zayd") as ModelDef
	var has_hilt: bool = false
	for part: ModelPartDef in zayd.parts:
		has_hilt = has_hilt or part.id == &"grandfather_hilt"
	check(has_hilt, "Zayd's default skin always wears the grandfather_hilt part")
	for id: StringName in ContentDB.ids("model"):
		var def := ContentDB.get_def("model", id) as ModelDef
		check(def.height_m > 0.5 and def.girth > 0.0, "%s: positive size and girth (never a negative scale)" % id)
