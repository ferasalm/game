extends TestCase
## Asset manifest: every shipped asset has a source and licence; the checker catches missing entries,
## empty licences and entries without files (fixtures), and ignores notes, .import files and the manifest.


func test_shipped_assets_are_all_listed() -> void:
	check_eq(AssetManifest.check(), PackedStringArray(), "assets/manifest.json covers assets/")


func test_good_fixture_passes() -> void:
	check_eq(AssetManifest.check("res://core/tests/fixtures/assets_ok"), PackedStringArray(), "ok fixture")


func test_bad_fixture_reports_each_problem() -> void:
	var text: String = "\n".join(AssetManifest.check("res://core/tests/fixtures/assets_bad"))
	check(text.contains("'a.txt' has an empty licence"), "empty licence reported: " + text)
	check(text.contains("'gone.txt' has no file"), "entry without file reported")
	check(text.contains("'unlisted.txt' has no manifest entry"), "unlisted file reported")


func test_notes_and_import_files_are_not_assets() -> void:
	var found: PackedStringArray = AssetManifest.files_under("res://assets")
	for path: String in found:
		check(not path.ends_with(".md") and not path.ends_with(".import") and path != "manifest.json", "skips " + path)
