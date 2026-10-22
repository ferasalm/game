extends TestCase
## The owner's music choices (DECISIONS 2026-10-22): menus and the herb stall keep the area music (no screen maps
## them), every patrol names one of the three battle themes and all three are used, and every track's file exists.

const BATTLE_THEMES: Array[StringName] = [&"battle", &"battle_2", &"battle_3"]


func test_menus_and_the_stall_keep_the_area_music() -> void:
	for id: StringName in [&"pause", &"items", &"equipment", &"shop"]:
		check(ContentDB.get_def("screen_music", id) == null, "%s has no track of its own" % id)


func test_patrols_use_the_three_battle_themes() -> void:
	var used: Dictionary[StringName, bool] = {}
	for id: StringName in ContentDB.ids("encounter"):
		var encounter := ContentDB.get_def("encounter", id) as EncounterDef
		if not id.begins_with("patrol") and id != &"rooftop_patrol":
			continue
		check(encounter.music in BATTLE_THEMES, "%s plays a battle theme (%s)" % [id, encounter.music])
		used[encounter.music] = true
	check_eq(used.size(), BATTLE_THEMES.size(), "all three battle themes play somewhere")


func test_every_track_has_its_file() -> void:
	for id: StringName in ContentDB.ids("music"):
		var def := ContentDB.get_def("music", id) as MusicDef
		check(ResourceLoader.exists(def.path), "%s: %s exists" % [id, def.path])
