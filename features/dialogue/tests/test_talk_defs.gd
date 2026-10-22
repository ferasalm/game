extends TestCase
## Checks that talks.json is well formed and all referenced dialogue ids exist in ContentDB.


func test_talks_content_well_formed() -> void:
	check(ContentDB.ids("talk").size() > 0, "talk definitions exist")
	check(ContentDB.ids("talk").has(&"herb_seller"), "herb_seller talk exists")
	for talk_id: StringName in ContentDB.ids("talk"):
		var def := ContentDB.get_def("talk", talk_id) as TalkDef
		check(def != null, "%s is a TalkDef" % talk_id)
		check(not def.first.is_empty(), "%s has first dialogue" % talk_id)
		check(ContentDB.get_def("dialogue", def.first) != null, "%s: first %s exists" % [talk_id, def.first])
		if not def.after_battle.is_empty():
			check(ContentDB.get_def("dialogue", def.after_battle) != null, "%s: after_battle %s exists" % [talk_id, def.after_battle])
		check(def.chats.size() > 0, "%s has chats" % talk_id)
		for chat_id: StringName in def.chats:
			check(ContentDB.get_def("dialogue", chat_id) != null, "%s: chat %s exists" % [talk_id, chat_id])
