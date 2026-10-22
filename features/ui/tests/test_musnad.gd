extends TestCase
## The written language of Sana'a in 2150 is Musnad only: no Arabic script in any CSV, JSON or script; every
## *_MUSNAD and WORLD_SIGN_* text holds only Musnad letters, spaces and arrows; the Musnad font draws it.

const ARABIC: Array[Vector2i] = [Vector2i(0x0600, 0x06FF), Vector2i(0x0750, 0x077F), Vector2i(0xFB50, 0xFDFF), Vector2i(0xFE70, 0xFEFF)]
const SKIP: Array[String] = [".godot", ".claude", ".git", "inbox", "tools", "docs", "addons"]
const ARROWS: Array[int] = [0x2190, 0x2192]
const MUSNAD_FIRST: int = 0x10A60
const MUSNAD_LAST: int = 0x10A7F


func test_no_arabic_script_in_the_game_files() -> void:
	var found: Array[String] = []
	_scan("res://", found)
	check_eq(found, [] as Array[String], "files holding Arabic code points")


func _scan(dir_path: String, found: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(dir_path):
		if not SKIP.has(sub):
			_scan(dir_path.path_join(sub), found)
	for file: String in DirAccess.get_files_at(dir_path):
		if file.get_extension() in ["csv", "json", "gd", "tscn", "tres"]:
			var path: String = dir_path.path_join(file)
			if _has_arabic(FileAccess.get_file_as_string(path)):
				found.append(path)


func _has_arabic(text: String) -> bool:
	for i: int in text.length():
		var code: int = text.unicode_at(i)
		for span: Vector2i in ARABIC:
			if code >= span.x and code <= span.y:
				return true
	return false


func test_musnad_and_sign_texts_hold_only_musnad() -> void:
	var count: int = 0
	for file: String in DirAccess.get_files_at("res://localization"):
		if file.get_extension() != "csv":
			continue
		for line: String in FileAccess.get_file_as_string("res://localization/" + file).split("\n"):
			var key: String = line.get_slice(",", 0)
			if key.ends_with("_MUSNAD") or key.begins_with("WORLD_SIGN_"):
				count += 1
				var text: String = line.substr(key.length() + 1).strip_edges()
				check(not text.is_empty() and _only_musnad(text), "%s is Musnad letters, spaces and arrows only" % key)
	check(count >= 10, "found the Musnad and sign keys (%d)" % count)


func _only_musnad(text: String) -> bool:
	for i: int in text.length():
		var code: int = text.unicode_at(i)
		if code != 0x20 and not ARROWS.has(code) and (code < MUSNAD_FIRST or code > MUSNAD_LAST):
			return false
	return true


func test_the_money_sign_is_plain_yr() -> void:
	check_eq(Ui.text("MONEY_GLYPH"), "YR", "the riyal sign")


func test_the_font_draws_every_musnad_text_and_labels_use_it() -> void:
	var font: Font = Ui.theme().get_font(&"font", &"MusnadLabel")
	for key: String in ["TITLE_GAME_MUSNAD", "PAUSE_HEADING_MUSNAD", "SABIL_TITLE_MUSNAD", "WORLD_SIGN_SOUQ"]:
		var text: String = Ui.text(key)
		for i: int in text.length():
			check(text[i] == " " or font.has_char(text.unicode_at(i)), "%s letter %d has a glyph" % [key, i])
	var pair: Control = Ui.title_pair("Pause", Ui.text("PAUSE_HEADING_MUSNAD"))
	var right := pair.get_child(1) as Label
	check_eq(right.theme_type_variation, &"MusnadLabel", "the second heading line is a Musnad label")
	pair.free()
