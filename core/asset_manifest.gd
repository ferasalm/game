class_name AssetManifest
extends RefCounted
## Checks assets/manifest.json: every file under the assets folder (except *.import, .gdignore, *.md and the
## manifest itself) has an entry with a non-empty source and licence. Entry fields: id, path (relative to the
## assets folder), source, licence, prompt. Returns the problems found (empty means valid).

const MANIFEST_FILE: String = "manifest.json"
const SKIPPED_SUFFIXES: PackedStringArray = [".import", ".md", ".uid"]  # .uid: Godot's id sidecar (videos get one)


static func check(root: String = "res://assets") -> PackedStringArray:
	var problems := PackedStringArray()
	var entries: Dictionary[String, Dictionary] = _read_entries(root, problems)
	for path: String in entries:
		if not FileAccess.file_exists(root.path_join(path)):
			problems.append("manifest entry '%s' has no file" % path)
		for field: String in ["source", "licence"]:
			if str(entries[path].get(field, "")).strip_edges().is_empty():
				problems.append("manifest entry '%s' has an empty %s" % [path, field])
	for path: String in files_under(root):
		if not entries.has(path):
			problems.append("asset '%s' has no manifest entry" % path)
	return problems


## Asset files under root as paths relative to root (manifest, notes and import files left out).
static func files_under(root: String, sub: String = "") -> PackedStringArray:
	var out := PackedStringArray()
	var dir_path: String = root.path_join(sub) if not sub.is_empty() else root
	for dir_name: String in DirAccess.get_directories_at(dir_path):
		out.append_array(files_under(root, sub.path_join(dir_name)))
	for file: String in DirAccess.get_files_at(dir_path):
		if _is_asset(file, sub):
			out.append(sub.path_join(file))
	return out


static func _is_asset(file: String, sub: String) -> bool:
	if file == MANIFEST_FILE and sub.is_empty() or file == ".gdignore":
		return false
	for suffix: String in SKIPPED_SUFFIXES:
		if file.ends_with(suffix):
			return false
	return true


static func _read_entries(root: String, problems: PackedStringArray) -> Dictionary[String, Dictionary]:
	var out: Dictionary[String, Dictionary] = {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(root.path_join(MANIFEST_FILE)))
	if not (parsed is Dictionary) or not ((parsed as Dictionary).get("assets") is Array):
		problems.append("%s/%s: missing or not {\"assets\": [...]}" % [root, MANIFEST_FILE])
		return out
	for entry: Variant in ((parsed as Dictionary)["assets"] as Array):
		if entry is Dictionary and (entry as Dictionary).get("path") is String:
			out[(entry as Dictionary)["path"] as String] = entry as Dictionary
		else:
			problems.append("manifest entry without a text 'path'")
	return out
