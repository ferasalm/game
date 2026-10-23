class_name BattleEndPanel
extends PanelContainer
## The end-of-battle panel in the middle of the screen. Victory: the spoils (the riyal the fight pays, herbs, and new
## items in their rarity colours, from set_loot / set_rewards) and Continue. Defeat: Retry or Back to the rooftop
## (the arena normally opens the Defeat screen instead; the panel is the fallback).

## The player's pick: &"victory" (continue), &"retry" or &"defeat" (back to the rooftop).
signal picked(result: StringName)

var _view: BattleViewDef
var _title: Label
var _loot_box: VBoxContainer
var _row: HBoxContainer
var _buttons: Array[Button] = []
var _loot: Array[StringName] = []
var _shown_loot: Array[StringName] = []
var _money: int = 0
var _herbs: Dictionary = {}
var _level_ups: Array = []


func setup(view: BattleViewDef) -> void:
	_view = view
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", roundi(view.margin / 2.0))
	box.custom_minimum_size.x = view.end_panel_w
	add_child(box)
	_title = BattleStyle.label("", &"BannerLabel")
	_title.add_theme_font_size_override("font_size", view.end_title_font)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	box.add_child(Ui.divider())
	_loot_box = VBoxContainer.new()
	box.add_child(_loot_box)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", view.margin)
	box.add_child(_row)
	visible = false


## The guaranteed loot of this fight (item ids); on a victory the ones not owned yet are listed.
func set_loot(item_ids: Array[StringName]) -> void:
	_loot = item_ids


## What the win pays: riyal and herbs {consumable id: count}, listed above the new items.
func set_rewards(money: int, herbs: Dictionary) -> void:
	_money = money
	_herbs = herbs


## The LevelUp events to display on victory.
func set_level_ups(level_ups: Array) -> void:
	_level_ups = level_ups


func shown_level_ups() -> Array:
	return _level_ups


## The riyal line the panel shows right now (0 when none: a defeat, or a fight that pays nothing).
func shown_money() -> int:
	return _money if _loot_box.visible and _money > 0 else 0


## The item ids the panel lists right now (victory only).
func shown_loot() -> Array[StringName]:
	return _shown_loot


func show_result(result: StringName) -> void:
	visible = true
	AudioDirector.play_sfx(result)
	_title.text = BattleStyle.text("UI_VICTORY" if result == &"victory" else "UI_DEFEAT")
	for button: Button in _buttons:
		_row.remove_child(button)
		button.queue_free()
	_buttons.clear()
	_fill_loot(result == &"victory")
	if result == &"victory":
		_add("UI_CONTINUE", &"victory")
	else:
		_add("UI_RETRY", &"retry")
		_add("UI_BACK_TO_ROOFTOP", &"defeat")
	if is_inside_tree() and not _buttons.is_empty():
		_buttons[0].grab_focus()


## The buttons now showing, in order.
func buttons() -> Array[Button]:
	return _buttons


func _fill_loot(won: bool) -> void:
	for child: Node in _loot_box.get_children():
		_loot_box.remove_child(child)
		child.queue_free()
	_shown_loot = []
	if won:
		for item_id: StringName in _loot:
			if not GameState.inventory.has(item_id):
				_shown_loot.append(item_id)
	var rewards: bool = won and (_money > 0 or not _herbs.is_empty() or not _level_ups.is_empty())
	_loot_box.visible = not _shown_loot.is_empty() or rewards
	if not _loot_box.visible:
		return
	_loot_box.add_child(BattleStyle.label(BattleStyle.text("UI_SPOILS"), &"CaptionLabel"))
	if rewards:
		_add_rewards()
		_add_level_ups()
	for item_id: StringName in _shown_loot:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", _view.margin)
		line.add_child(UiRarity.item_label(item_id))
		line.add_child(UiRarity.tag(UiRarity.of_item(item_id)))
		_loot_box.add_child(line)


## The riyal line and one line per herb stack.
func _add_rewards() -> void:
	if _money > 0:
		_loot_box.add_child(BattleStyle.label(BattleStyle.text("BATTLE_REWARD_MONEY") % _money, &"NameLabel",
			Ui.style().colour(&"c_brass")))
	for herb_id: Variant in _herbs:
		var def := ContentDB.get_def("consumable", StringName(str(herb_id))) as ConsumableDef
		if def != null:
			_loot_box.add_child(BattleStyle.label(BattleStyle.text("BATTLE_REWARD_HERB") % [
				BattleStyle.text(def.name_key), int(_herbs[herb_id])], &"NameLabel"))


func _add_level_ups() -> void:
	for lu: Variant in _level_ups:
		var hero_id: StringName = lu.hero if "hero" in lu else &""
		var hero_name: String = str(hero_id).capitalize()
		var hero_def := ContentDB.get_def("combatant", hero_id) as CombatantDef
		if hero_def != null and not hero_def.name_key.is_empty():
			hero_name = BattleStyle.text(hero_def.name_key)
		var to_lv: int = int(lu.to_level) if "to_level" in lu else 1
		var title: String = BattleStyle.text("UI_LEVEL_UP") % [hero_name, to_lv]
		var parts: PackedStringArray = PackedStringArray()
		var gains: Dictionary = lu.gains if "gains" in lu else {}
		for stat_pair: Array in [["max_hp", "HP"], ["max_sp", "SP"], ["attack", "ATK"], ["defense", "DEF"], ["agility", "AGI"], ["luck", "LCK"]]:
			var val: int = int(gains.get(StringName(stat_pair[0]), 0))
			if val > 0:
				parts.append("%s +%d" % [stat_pair[1], val])
		var line_text: String = "%s  %s" % [title, "  ".join(parts)] if not parts.is_empty() else title
		_loot_box.add_child(BattleStyle.label(line_text, &"NameLabel", Ui.style().colour(&"c_gold")))


func _add(key: String, result: StringName) -> void:
	var button := Button.new()
	button.text = BattleStyle.text(key)
	button.custom_minimum_size = Vector2(Ui.style().size(&"s_end_button_w"), Ui.style().size(&"s_end_button_h"))
	button.pressed.connect(_pick.bind(result))
	_row.add_child(button)
	_buttons.append(button)


func _pick(result: StringName) -> void:
	picked.emit(result)
