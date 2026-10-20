extends TestCase
## Player text: every localization CSV loads, keys translate, and a malformed file is reported.


func test_shipped_text_loads_and_translates() -> void:
	var db: Node = load("res://core/text_db.gd").new()
	check_eq(db.call("load_all"), PackedStringArray(), "no text problems")
	check_eq(String(TranslationServer.translate("WORLD_ROOFTOP_NAME")), "Souq rooftops", "a key translates")
	db.free()


func test_bad_header_is_reported() -> void:
	var db: Node = load("res://core/text_db.gd").new()
	var problems: PackedStringArray = db.call("load_all", "res://core/tests/fixtures/bad_text")
	check(problems.size() == 1 and problems[0].contains("keys,<lang>"), "header check")
	db.free()
