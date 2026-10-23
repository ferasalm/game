extends TestCase
## ActionDef new fields: target, heal, revive, vfx (validated on load), and the shipped actions: every one has
## a vfx from the agreed list, and the tech moves have the shape the design asks for.


func _read(props: Dictionary) -> PackedStringArray:
	var data: Dictionary = {"id": "m", "name_key": "X", "sp_cost": 0, "power": 0, "cast_speed": 1.0, "recovery": 0, "knockback": 0}
	data.merge(props, true)
	var errors := PackedStringArray()
	var action := ActionDef.new()
	action.read(DefReader.new(data, "test", errors))
	return errors


func test_defaults_are_a_foe_move_with_no_heal() -> void:
	var errors := PackedStringArray()
	var action := ActionDef.new()
	action.read(DefReader.new({"id": "m", "name_key": "X", "sp_cost": 0, "power": 5, "cast_speed": 1.0, "recovery": 0, "knockback": 0}, "t", errors))
	check_eq(errors, PackedStringArray(), "valid")
	check_eq(action.target, &"foe", "default target")
	check(action.is_hostile() and action.needs_picker(), "a foe move: hostile, needs a pick")
	check_eq(action.heal, 0, "no heal")
	check(not action.revive, "no revive")
	check_eq(action.vfx, &"", "empty vfx lets the view choose")


func test_bad_combinations_are_reported() -> void:
	check("\n".join(_read({"target": "everyone"})).contains("target"), "unknown target")
	check("\n".join(_read({"vfx": "fireball"})).contains("vfx"), "unknown vfx")
	check("\n".join(_read({"target": "foe", "heal": 10})).contains("cannot heal"), "a foe move cannot heal")
	check("\n".join(_read({"target": "ally", "power": 5, "heal": 10})).contains("cannot hurt"), "an ally move has power 0")
	check("\n".join(_read({"target": "self", "cancels_cast": true})).contains("cannot hurt or cancel"), "or cancel")
	check("\n".join(_read({"target": "ally", "revive": true})).contains("revive"), "revive needs heal")
	check("\n".join(_read({"target": "all_allies", "heal": 10, "revive": true})).contains("revive"), "revive needs target ally")
	check_eq(_read({"target": "ally", "heal": 10, "revive": true, "vfx": "heal"}), PackedStringArray(), "a valid revive")


func test_target_kinds_and_pickers() -> void:
	var expect: Dictionary[StringName, Array] = {
		&"foe": [true, true], &"ally": [false, true], &"self": [false, false],
		&"all_foes": [true, false], &"all_allies": [false, false]}
	for target: StringName in expect:
		var action := ActionDef.new()
		action.target = target
		check_eq(action.is_hostile(), (expect[target] as Array)[0], "%s hostile" % target)
		check_eq(action.needs_picker(), (expect[target] as Array)[1], "%s needs a pick" % target)


func test_every_shipped_action_has_a_known_vfx() -> void:
	check_eq(ActionDef.VFX_KINDS.size(), 15, "fifteen effect kinds (including none)")
	for action_id: StringName in ContentDB.ids("action"):
		if action_id == &"flee":
			continue
		var action := ContentDB.get_def("action", action_id) as ActionDef
		check(ActionDef.VFX_KINDS.has(action.vfx), "%s has vfx '%s'" % [action_id, action.vfx])
		check(tr(action.name_key) != action.name_key, "%s has a name" % action_id)
		check(action.desc_key.is_empty() or tr(action.desc_key) != action.desc_key, "%s has a description" % action_id)


func test_the_tech_moves_have_the_designed_shape() -> void:
	var jab := ContentDB.get_def("action", &"piston_jab") as ActionDef
	check(not jab.cancels_cast and jab.is_hostile(), "piston jab shoves without cancelling")
	var arc := ContentDB.get_def("action", &"arc_discharge") as ActionDef
	check_eq(arc.target, &"all_foes", "arc discharge hits all foes")
	var guard := ContentDB.get_def("action", &"reactive_guard") as ActionDef
	check(guard.target == &"self" and guard.applies_status == &"guarded", "reactive guard is a self guard")
	var mend := ContentDB.get_def("action", &"nanite_mend") as ActionDef
	check(mend.target == &"ally" and mend.heal > 0 and not mend.revive, "nanite mend heals an ally")
	var link := ContentDB.get_def("action", &"overclock_link") as ActionDef
	check(link.target == &"all_allies" and link.applies_status == &"overclocked", "overclock link buffs all allies")
	var lance := ContentDB.get_def("action", &"overload_lance") as ActionDef
	check(lance.target == &"foe" and not lance.is_melee and lance.power >= 50, "overload lance is a big ranged hit")
	check((ContentDB.get_def("action", &"reboot_pulse") as ActionDef).revive, "reboot pulse revives")


func test_new_statuses() -> void:
	var guarded := ContentDB.get_def("status", &"guarded") as StatusDef
	check_eq(guarded.damage_taken, 0.6, "guarded: damage taken x0.6")
	var overclocked := ContentDB.get_def("status", &"overclocked") as StatusDef
	check(overclocked.wait_speed > 1.0 and overclocked.cast_speed > 1.0, "overclocked: timeline speed up")
