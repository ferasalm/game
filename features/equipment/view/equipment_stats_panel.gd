class_name EquipmentStatsPanel
extends PanelContainer
## purpose: Stats preview panel (440x560) showing now vs after comparison and derived battle rolls.

class StagedState extends RefCounted:
	var xp: Dictionary = {}
	var equipment: Dictionary = {}
	var sockets: Dictionary = {}
	var upgrades: Dictionary = {}

var _loader: BattleLoader
var _rules: BattleRulesDef
var _grid: GridContainer
var _now_hdr: Label
var _after_hdr: Label
var _now_labels: Dictionary[String, Label] = {}
var _after_labels: Dictionary[String, Label] = {}
var _last_now: CombatantDef = null
var _last_after: CombatantDef = null


func _init() -> void:
	custom_minimum_size = Vector2(440.0, 560.0)
	size = Vector2(440.0, 560.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loader = BattleLoader.from_db(ContentDB)
	_rules = ContentDB.get_def("battle_rules", &"default") as BattleRulesDef
	if _rules == null:
		_rules = BattleRulesDef.new()


func _ready() -> void:
	_build_ui()


func update_stats(hero: StringName, preview_slot: StringName = &"", preview_item: StringName = &"") -> void:
	var now_def: CombatantDef = _loader.hero_from_state(hero, GameState)
	var staged := StagedState.new()
	staged.xp = GameState.xp
	staged.equipment = GameState.equipment.duplicate()
	staged.sockets = GameState.sockets
	staged.upgrades = GameState.upgrades
	if preview_slot != &"" and preview_item != &"":
		staged.equipment[preview_slot] = preview_item
	var after_def: CombatantDef = _loader.hero_from_state(hero, staged)
	_last_now = now_def
	_last_after = after_def
	_refresh_display(hero, now_def, after_def)


func last_after() -> CombatantDef:
	return _last_after


func last_now() -> CombatantDef:
	return _last_now


func header_now() -> Label:
	return _now_hdr


func header_after() -> Label:
	return _after_hdr


func _build_ui() -> void:
	for child: Node in get_children():
		child.queue_free()
	var style: UiStyleDef = Ui.style()
	add_theme_stylebox_override("panel", UiBoxes.panel(style, &"panel"))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", style.size(&"s_pad"))
	add_child(vbox)

	var title_plate := Ui.title_plate(Ui.text("EQUIP_STATS_TITLE"), "")
	vbox.add_child(title_plate)
	vbox.add_child(Ui.divider())

	var header_row := HBoxContainer.new()
	header_row.name = "StatsHeader"
	header_row.add_theme_constant_override("separation", 14)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 90.0
	header_row.add_child(spacer)
	_now_hdr = Ui.label(Ui.text("EQUIP_HEADER_NOW"), &"CaptionLabel", style.colour(&"c_muted"))
	_now_hdr.custom_minimum_size.x = 60.0
	_now_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(_now_hdr)
	var arrow_sp := Control.new()
	arrow_sp.custom_minimum_size.x = 24.0
	header_row.add_child(arrow_sp)
	_after_hdr = Ui.label(Ui.text("EQUIP_HEADER_AFTER"), &"CaptionLabel", style.colour(&"c_muted"))
	_after_hdr.custom_minimum_size.x = 80.0
	_after_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_row.add_child(_after_hdr)
	vbox.add_child(header_row)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(_grid)

	var keys: Array[String] = ["HP", "SP", "ATK", "DEF", "AGI", "LCK", "WT", "Hit %", "Crit %", "Flee %"]
	for k: String in keys:
		_add_stat_row(k)


func _add_stat_row(stat_key: String) -> void:
	var style: UiStyleDef = Ui.style()
	var label := Ui.label(stat_key, &"CaptionLabel", style.colour(&"c_cyan"))
	label.custom_minimum_size.x = 90.0
	_grid.add_child(label)

	var now_lbl := Ui.label("0", &"NumberLabel")
	now_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	now_lbl.custom_minimum_size.x = 60.0
	_grid.add_child(now_lbl)
	_now_labels[stat_key] = now_lbl

	var arrow := Ui.label("→", &"CaptionLabel", style.colour(&"c_muted"))
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.custom_minimum_size.x = 24.0
	_grid.add_child(arrow)

	var after_lbl := Ui.label("0", &"NumberLabel")
	after_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	after_lbl.custom_minimum_size.x = 70.0
	_grid.add_child(after_lbl)
	_after_labels[stat_key] = after_lbl


func _refresh_display(hero: StringName, now_def: CombatantDef, after_def: CombatantDef) -> void:
	if now_def == null or after_def == null:
		return
	var style: UiStyleDef = Ui.style()
	_set_row("HP", float(now_def.max_hp), float(after_def.max_hp), "%d", style)
	_set_row("SP", float(now_def.max_sp), float(after_def.max_sp), "%d", style)
	_set_row("ATK", float(now_def.attack), float(after_def.attack), "%d", style)
	_set_row("DEF", float(now_def.defense), float(after_def.defense), "%d", style)
	_set_row("AGI", float(now_def.agility), float(after_def.agility), "%d", style)
	_set_row("LCK", float(now_def.luck), float(after_def.luck), "%d", style)
	_set_row("WT", now_def.weight, after_def.weight, "%.1f" if (fmod(now_def.weight, 1.0) != 0.0 or fmod(after_def.weight, 1.0) != 0.0) else "%d", style)

	var now_rolls: Dictionary = _calc_rolls(hero, now_def)
	var after_rolls: Dictionary = _calc_rolls(hero, after_def)
	_set_row("Hit %", now_rolls["hit"] * 100.0, after_rolls["hit"] * 100.0, "%d%%", style)
	_set_row("Crit %", now_rolls["crit"] * 100.0, after_rolls["crit"] * 100.0, "%d%%", style)
	_set_row("Flee %", now_rolls["flee"] * 100.0, after_rolls["flee"] * 100.0, "%d%%", style)


func _calc_rolls(hero: StringName, def: CombatantDef) -> Dictionary:
	var hero_unit := UnitState.create(def, hero, 0, 0, _rules)
	var foe_def := CombatantDef.new()
	foe_def.agility = 40
	var foe_unit := UnitState.create(foe_def, &"foe", 1, 0, _rules)
	var hit: float = BattleRolls.hit_chance(hero_unit, foe_unit, _rules)
	var crit: float = BattleRolls.crit_chance(hero_unit, _rules)
	var flee: float = BattleRolls.flee_chance([hero_unit], [foe_unit], 0, 0, _rules)
	return {"hit": hit, "crit": crit, "flee": flee}


func _set_row(stat_key: String, now_val: float, after_val: float, fmt: String, style: UiStyleDef) -> void:
	if not _now_labels.has(stat_key) or not _after_labels.has(stat_key):
		return
	_now_labels[stat_key].text = fmt % now_val
	var after_lbl: Label = _after_labels[stat_key]
	var is_wt: bool = (stat_key == "WT")
	var better: bool = (after_val < now_val) if is_wt else (after_val > now_val)
	var worse: bool = (after_val > now_val) if is_wt else (after_val < now_val)
	var arrow: String = ""
	if better:
		arrow = " ▲"
		after_lbl.add_theme_color_override("font_color", style.colour(&"c_good"))
	elif worse:
		arrow = " ▼"
		after_lbl.add_theme_color_override("font_color", style.colour(&"c_bad"))
	else:
		after_lbl.remove_theme_color_override("font_color")
	after_lbl.text = (fmt % after_val) + arrow
