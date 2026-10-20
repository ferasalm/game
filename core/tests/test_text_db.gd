extends TestCase
## Player text: every localization CSV loads, keys translate, and a malformed file is reported.


func test_shipped_text_loads_and_translates() -> void:
	var db: Node = load("res://core/text_db.gd").new()
	check_eq(db.call("load_all"), PackedStringArray(), "no text problems")
	check_eq(String(TranslationServer.translate("WORLD_ROOFTOP_NAME")), "Souq rooftops", "a key translates")
	db.free()


func test_bad_header_and_duplicate_key_are_reported() -> void:
	var db: Node = load("res://core/text_db.gd").new()
	var problems: PackedStringArray = db.call("load_all", "res://core/tests/fixtures/bad_text")
	var joined: String = "
".join(problems)
	check(joined.contains("keys,<lang>"), "header check")
	check(joined.contains("key DUP_KEY is already in"), "duplicate key check")
	db.free()


## Godot's CSV translation import breaks a fresh clone (DECISIONS 2026-10-21): every CSV must use "keep".
func test_every_text_csv_uses_the_keep_importer() -> void:
	for file: String in DirAccess.get_files_at("res://localization"):
		if file.ends_with(".csv"):
			var config := ConfigFile.new()
			var path: String = "res://localization/%s.import" % file
			check(config.load(path) == OK and str(config.get_value("remap", "importer", "")) == "keep",
				"%s uses the keep importer" % file)
