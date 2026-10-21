class_name PaintedAtlases
extends RefCounted
## The code-painted world atlases that the offline painterly bake repaints, by atlas id: tile_<pattern> for every
## playable surface pattern and facade_<building> / facade_<building>_emit for every tower-house. Base level only
## (no mipmaps), RGBA8, so tools/export_atlases.gd, tools/art/painterly_bake.py and the bake-hash test agree byte
## for byte. bake.json in each baked folder records the sha256 of every input it was baked from.

const SKIPPED_PATTERNS: Array[StringName] = [&"far_windows"]  ## far silhouettes stay unshaded pixel dots
const BAKE_RECORD: String = "bake.json"


static func all(palette: PaletteDef) -> Dictionary[String, Image]:
	var out: Dictionary[String, Image] = {}
	for pattern: StringName in SurfacePainter.PATTERNS:
		if not SKIPPED_PATTERNS.has(pattern):
			out["tile_" + pattern] = _base(SurfacePainter.paint(pattern, palette.colors)[0])
	for building_id: StringName in ContentDB.ids("building"):
		var def := ContentDB.get_def("building", building_id) as BuildingDef
		var images: Array[Image] = SurfaceMaterials.facade_images(def, palette)
		out["facade_" + building_id] = _base(images[0])
		out["facade_%s_emit" % building_id] = _base(images[1])
	return out


## Writes every atlas as <dir>/<atlas_id>.png (tools/export_atlases.gd); returns how many were written.
static func export_to(dir: String) -> int:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var atlases: Dictionary[String, Image] = all(palette)
	for atlas_id: String in atlases:
		if atlases[atlas_id].save_png(dir.path_join(atlas_id + ".png")) != OK:
			push_error("PaintedAtlases: could not write %s" % atlas_id)
	return atlases.size()


## sha256 (hex) of an atlas's RGBA8 pixel bytes: the same bytes Pillow's Image.tobytes() gives for the exported PNG.
static func digest(image: Image) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(image.get_data())
	return ctx.finish().hex_encode()


## The input hashes a baked recipe folder was made from ({} when it has none).
static func baked_inputs(bake: StringName) -> Dictionary:
	var path: String = PaintedMaterials.BAKED_DIR.path_join(String(bake)).path_join(BAKE_RECORD)
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (data as Dictionary).get("inputs", {}) as Dictionary if data is Dictionary else {}


static func _base(image: Image) -> Image:
	var copy := image.duplicate() as Image
	copy.clear_mipmaps()
	if copy.get_format() != Image.FORMAT_RGBA8:
		copy.convert(Image.FORMAT_RGBA8)
	return copy
