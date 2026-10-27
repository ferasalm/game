extends SceneTree
## Rodin step 1: simplifies a Rodin glb mesh with Godot's LOD generator and writes the index buffer (env SRC, IDX, MAX_TRIS, DST);
## rewrite_glb.py then builds the slim glb (usage: docs/archive/design-3d/characters-3d.md 8).

func _initialize() -> void:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(OS.get_environment("SRC"), state) != OK:
		push_error("load failed")
		quit(1)
		return
	var max_tris: int = OS.get_environment("MAX_TRIS").to_int()
	for gm: GLTFMesh in state.get_meshes():
		_slim(gm.mesh, max_tris)
	for node: GLTFNode in state.get_nodes():
		if node.resource_name == "head":
			node.resource_name = "Head"
	state.set_images([] as Array[Texture2D])
	state.set_materials([] as Array[Material])
	state.set_textures([] as Array[GLTFTexture])
	var err: int = doc.write_to_filesystem(state, OS.get_environment("DST"))
	print("write: ", err)
	quit(err)

func _slim(mesh: ImporterMesh, max_tris: int) -> void:
	var arrays: Array = mesh.get_surface_arrays(0)
	var mat: Material = mesh.get_surface_material(0)
	var name: String = mesh.get_surface_name(0)
	print("before: ", (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3)
	mesh.generate_lods(60.0, 25.0, [])
	var best: PackedInt32Array = PackedInt32Array()
	for i: int in mesh.get_surface_lod_count(0):
		var idx: PackedInt32Array = mesh.get_surface_lod_indices(0, i)
		print("lod ", i, ": ", idx.size() / 3)
		if idx.size() / 3 <= max_tris and idx.size() > best.size():
			best = idx
	arrays[Mesh.ARRAY_INDEX] = best
	mesh.clear()
	mesh.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, null, name)
	print("after: ", best.size() / 3, " verts: ", (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	var f := FileAccess.open(OS.get_environment("IDX"), FileAccess.WRITE)
	f.store_buffer(best.to_byte_array())
	f.close()
