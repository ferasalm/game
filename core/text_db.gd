extends Node
## Player text (autoload TextDB): loads every res://localization/*.csv (header "keys,<lang>,...") into the
## TranslationServer at startup, so tr("KEY") works. The CSVs use the "keep" importer: no generated files.

const TEXT_ROOT: String = "res://localization"


func _ready() -> void:
	for problem: String in load_all():
		push_error("TextDB: " + problem)


## Loads every CSV under root; returns the problems found (empty means valid).
func load_all(root: String = TEXT_ROOT) -> PackedStringArray:
	var errors := PackedStringArray()
	var by_lang: Dictionary[String, Translation] = {}
	var seen: Dictionary[String, String] = {}
	for file: String in DirAccess.get_files_at(root):
		if file.ends_with(".csv"):
			_load_file(root.path_join(file), by_lang, seen, errors)
	for lang: String in by_lang:
		TranslationServer.add_translation(by_lang[lang])
	return errors


func _load_file(path: String, by_lang: Dictionary[String, Translation], seen: Dictionary[String, String],
		errors: PackedStringArray) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var header: PackedStringArray = file.get_csv_line()
	if header.size() < 2 or header[0] != "keys":
		errors.append("%s: the first line must be keys,<lang>,..." % path)
		return
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2 or row[0].is_empty():
			continue
		if seen.has(row[0]):
			errors.append("%s: key %s is already in %s" % [path, row[0], seen[row[0]]])
		seen[row[0]] = path
		for col: int in range(1, mini(row.size(), header.size())):
			var lang: String = header[col]
			if not by_lang.has(lang):
				by_lang[lang] = Translation.new()
				by_lang[lang].locale = lang
			by_lang[lang].add_message(row[0], row[col])
