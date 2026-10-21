extends TestCase
## UI v2 helpers: list_row, party_card, money_counter, prompt_strip and its glyph keys, toast queue and host,
## interaction prompt fade, typed text, the qamariya transition sweep, and the head icons with their disc fallback.


func test_list_row_shows_name_count_tag_and_greys_when_disabled() -> void:
	var row: ListRow = Ui.list_row(null, "Pink herb", 3, UiRarity.colour(&"rare"), "HP+60") as ListRow
	tree.root.add_child(row)
	check_eq(row.name_text(), "Pink herb", "name")
	check_eq(row.count_text(), "x3", "count")
	check(row.custom_minimum_size.y >= Ui.style().size(&"s_list_row_h"), "row height from style")
	var labels: PackedStringArray = PackedStringArray()
	for node: Node in NodeWalk.all(row):
		if node is Label:
			labels.append((node as Label).text)
	check(labels.has("HP+60"), "tag chip text")
	row.set_enabled(false)
	check(row.disabled, "disabled")
	check_eq(row.get_child(0).get_child(1).get_theme_color("font_color"), Ui.style().colour(&"c_disabled"), "grey name")
	var hidden: ListRow = Ui.list_row(null, "Key", -1, Color.WHITE) as ListRow
	check_eq(hidden.count_text(), "", "negative count hides the count")
	hidden.free()
	row.free()


func test_party_card_numbers_ko_and_active_frame() -> void:
	GameState.reset()
	var card: PartyCard = Ui.party_card(&"zayd")
	tree.root.add_child(card)
	check_eq(card.hp_text(), "400/400", "full HP from missing vitals")
	card.update(0, 5, false)
	check(card.is_ko(), "hp 0 shows KO")
	check_eq(card.hp_text(), "0/400", "hp text")
	check_eq(card.sp_text(), "5/24", "sp text")
	card.update(120, 10, false)
	check(not card.is_ko() and card.hp_value() == 120.0, "back up, bar moved at once without animation")
	card.set_active(true)
	check(card.has_theme_stylebox_override("panel"), "active hero gets its frame")
	check(card.custom_minimum_size.x == Ui.style().size(&"s_card_w"), "card width from style")
	card.free()


func test_money_counter_groups_digits_and_clamps() -> void:
	check_eq(PauseLogic.grouped(1240), "1,240", "thousands")
	check_eq(PauseLogic.grouped(999), "999", "no comma under 1000")
	check_eq(PauseLogic.grouped(1000000), "1,000,000", "millions")
	check_eq(PauseLogic.grouped(-5), "0", "negative is zero")
	var pill: MoneyCounter = Ui.money_counter()
	pill.set_amount(1240, false)
	check_eq(pill.shown_text(), "1,240", "shown at once without animation")
	check_eq(pill.amount(), 1240, "amount")
	pill.free()


func test_prompt_glyph_keys_and_all_translate() -> void:
	check_eq(PromptGlyph.key(&"accept", false), "UI_GLYPH_KEY_ACCEPT", "keyboard key")
	check_eq(PromptGlyph.key(&"back", true), "UI_GLYPH_PAD_BACK", "gamepad key")
	for action: StringName in [&"accept", &"back", &"menu", &"skip", &"cease", &"info", &"interact"]:
		for pad: bool in [false, true]:
			var key: String = PromptGlyph.key(action, pad)
			check(Ui.text(key) != key, "glyph text for " + key)


func test_prompt_strip_follows_the_last_device() -> void:
	PromptStrip.gamepad = false
	var strip: PromptStrip = Ui.prompt_strip([{"key": "accept", "text": "PROMPT_SELECT"}, {"key": "back", "text": "PROMPT_BACK"}])
	tree.root.add_child(strip)
	check_eq(strip.hints(), PackedStringArray(["Enter Select", "Esc Back"]), "keyboard glyphs")
	strip._input(InputEventJoypadButton.new())
	check_eq(strip.hints(), PackedStringArray(["A Select", "B Back"]), "gamepad glyphs after a pad press")
	check_eq(strip.get_child_count(), 2, "rebuilt to two hints")
	PromptStrip.gamepad = false
	strip.free()


func test_toast_queue_is_ordered_and_clamps_unknown_kinds() -> void:
	var queue := ToastQueue.new()
	queue.push("A", &"good")
	queue.push("B", &"weird")
	check_eq(queue.size(), 2, "two wait")
	check_eq(queue.take(), {"text": "A", "kind": &"good"}, "first in first out")
	check_eq(queue.take()["kind"], &"info", "unknown kind becomes info")
	check(queue.take().is_empty(), "empty queue gives an empty dictionary")


func test_toast_host_shows_one_at_a_time() -> void:
	var host := ToastHost.new()
	tree.root.add_child(host)
	host.show_toast("SABIL_SAVED", &"good")
	host.show_toast("SABIL_PATROLS", &"info")
	check_eq(host.current_text(), "Game saved.", "the first shows")
	check_eq(host.current_kind(), &"good", "its kind")
	check_eq(host.pending(), 1, "the second waits")
	host.free()


func test_interaction_prompt_fades_with_distance() -> void:
	check_eq(PromptGlyph.fade(1.0, 3.0, 7.0), 1.0, "close is opaque")
	check_eq(PromptGlyph.fade(5.0, 3.0, 7.0), 0.5, "halfway")
	check_eq(PromptGlyph.fade(9.0, 3.0, 7.0), 0.0, "far is gone")
	var prompt: InteractionPrompt = Ui.interaction_prompt("SABIL_PROMPT")
	check_eq(prompt.verb_text(), "Drink", "verb text")
	var style: UiStyleDef = Ui.style()
	check_eq(prompt.alpha_for(float(style.size(&"s_prompt_near"))), 1.0, "opaque at the near distance")
	check_eq(prompt.alpha_for(float(style.size(&"s_prompt_far"))), 0.0, "gone at the far distance")
	prompt.free()


func test_type_text_reveals_and_finish_shows_all() -> void:
	var label := Label.new()
	tree.root.add_child(label)
	var tween: Tween = Ui.type_text(label, "Hello")
	check(tween != null and label.visible_characters == 0, "starts hidden")
	check(UiType.is_typing(label, tween), "typing")
	UiType.finish(label, tween)
	check_eq(label.visible_characters, -1, "finish shows all")
	check(not UiType.is_typing(label, tween), "no longer typing")
	var loose := Label.new()
	check(Ui.type_text(loose, "Hi") == null and loose.visible_characters == -1, "out of the tree: shown at once")
	loose.free()
	label.free()


func test_transition_sweep_builds_five_shards_in_qamariya_colours() -> void:
	var host := Control.new()
	tree.root.add_child(host)
	var covered: Array[bool] = []
	var tween: Tween = Ui.transition_sweep(host, func() -> void: covered.append(true))
	check(tween != null, "a tween")
	check_eq(host.get_child_count(), 5, "five shards")
	for i: int in 5:
		check_eq((host.get_child(i) as ColorRect).color, Ui.style().colour(UiMotion.QAM_KEYS[i]), "shard %d colour" % i)
	host.free()


func test_icons_fall_back_to_a_disc_with_the_initial() -> void:
	check(CharacterIcons.texture(&"zayd") == null, "no icon file yet: null")
	check_eq(CharacterIcons.initial(&"zayd"), "Z", "initial from the name")
	check_eq(CharacterIcons.initial(&"nobody"), "?", "unknown character")
	var face: Control = CharacterIcons.face(&"bilqis", Ui.style().colour(&"c_party"))
	check_eq((face.get_child(0) as Label).text, "B", "the disc carries the initial")
	var disc: Texture2D = CharacterIcons.disc(Color.RED)
	check_eq(disc.get_width(), CharacterIcons.DISC_SIDE, "square disc")
	check(disc.get_image().get_pixel(0, 0).a == 0.0 and disc.get_image().get_pixel(32, 32).a == 1.0, "round: clear corners")
	for id: StringName in ContentDB.ids("combatant"):
		check(Ui.style().icons.has(String(id)), "icon path in content for " + id)
	face.free()
