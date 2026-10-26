class_name TestPlaytestDump
extends TestCase
## purpose: PlaytestDump builds the capture record with every key, plain JSON values, the note/log/event caps and a
## Windows-safe folder name.


func test_build_has_every_key() -> void:
	var data := PlaytestDump.build("note", "2026-10-26_21-05-33_042", "roof_scene",
			{"stage": &"roof", "room": &"prison_roof", "hero": Vector2(1.234, 2.345), "fight": {}}, [])
	for key: String in ["time", "scene", "stage", "room", "hero", "fight", "log", "note"]:
		check(data.has(key), "has " + key)
	check_eq(data["stage"], "roof", "a StringName becomes a String")
	check_eq(data["room"], "prison_roof", "the room id is a String")
	var hero: Array = data["hero"]
	check_eq(hero.size(), 2, "the hero is [x, y]")
	check(is_equal_approx(hero[0], 1.2), "x has one decimal")
	check(is_equal_approx(hero[1], 2.3), "y has one decimal")


func test_caps_the_note_log_and_events() -> void:
	var log_lines: Array = []
	for i: int in 80:
		log_lines.append("line %d" % i)
	var data := PlaytestDump.build("x".repeat(400), "stamp", "scene", {}, log_lines)
	check_eq((data["note"] as String).length(), PlaytestDump.NOTE_CAP, "the note is capped")
	check_eq((data["log"] as Array).size(), PlaytestDump.LOG_CAP, "the log is capped")
	check_eq(data["log"][0], "line 30", "the newest lines are kept")
	var events: Array = []
	for i: int in 20:
		events.append("event %d" % i)
	var fight := PlaytestDump.fight(12, [], events)
	check_eq(fight["ticks"], 12, "the tick is kept")
	check_eq((fight["events"] as Array).size(), PlaytestDump.EVENT_CAP, "the events are capped")


func test_json_round_trip() -> void:
	var data := PlaytestDump.build("note", "stamp", "scene", {"stage": &"roof", "hero": Vector2(1.0, 2.0)}, [])
	var json := JSON.new()
	check_eq(json.parse(JSON.stringify(data, "  ")), OK, "the record is valid JSON")
	check_eq(json.data["stage"], "roof", "the stage survives")
	check_eq((json.data["hero"] as Array).size(), 2, "the hero survives")


func test_folder_name_has_no_colons() -> void:
	var name: String = PlaytestDump.folder_name("2026-10-26T21:05:33", 42)
	check_eq(name, "2026-10-26_21-05-33_042", "the folder stamp")
	check(not name.contains(":"), "no colons for Windows")
