extends TestCase
## The shipped content loads with no problems, and the validator catches broken content.


func test_shipped_content_is_valid() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	var problems: PackedStringArray = db.call("load_all")
	check_eq(problems, PackedStringArray(), "no content problems")
	var zayd := db.call("get_def", "combatant", &"zayd") as CombatantDef
	check(zayd != null and zayd.actions.has(&"breaker"), "zayd knows breaker")
	db.free()


func test_broken_content_is_reported() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	var problems: PackedStringArray = db.call("load_all", "res://core/tests/fixtures/bad_content")
	var joined: String = "\n".join(problems)
	check(joined.contains("agility: 0 outside 1..99"), "range check")
	check(joined.contains("name_key: missing"), "missing field")
	check(joined.contains("needs missing action 'no_such_action'"), "dangling reference")
	check(joined.contains("is not a lowercase_identifier"), "id format")
	db.free()
