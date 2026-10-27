extends TestCase
## purpose: Every body-anchor share is read from content/art/visual.json, and a missing key is a content error.


func test_anchor_shares_come_from_visual_json() -> void:
	var rules := ContentDB.get_def("visual_rules", &"default") as VisualRulesDef
	check(rules != null, "the default visual rules load")
	if rules == null:
		return
	check_approx(rules.chest_height, 0.72, "chest height")
	check_approx(rules.belt_height, 0.55, "belt height")
	check_approx(rules.arm_height, 0.62, "arm height")
	check_approx(rules.hand_height, 0.5, "model hand height")
	check_approx(rules.pixel_hand_height, 0.55, "pixel hand height")
	check_approx(rules.belt_depth, 0.4, "belt depth")
	check_approx(rules.belt_side, 0.35, "pixel belt side")
	check_approx(rules.arm_side, 0.45, "arm side")
	check_approx(rules.hand_side, 0.5, "hand side")
	check_approx(rules.fallback_height, 1.8, "fallback height")


func test_model_anchors_use_the_rules_shares() -> void:
	var rules := ContentDB.get_def("visual_rules", &"default") as VisualRulesDef
	var size := Vector2(0.5, 1.8)
	var chest: Vector3 = ModelAnchors.fallback(&"chest", 1.0, size, rules)
	check_approx(chest.y, size.y * rules.chest_height, "chest height")
	var belt: Vector3 = ModelAnchors.fallback(&"belt", 1.0, size, rules)
	check_approx(belt.y, size.y * rules.belt_height, "belt height")
	check_approx(belt.z, size.x * rules.belt_depth, "belt depth")
	var arm: Vector3 = ModelAnchors.fallback(&"arm", -1.0, size, rules)
	check_approx(arm.x, -size.x * rules.arm_side, "arm side")
	check_approx(arm.y, size.y * rules.arm_height, "arm height")
	var hand: Vector3 = ModelAnchors.fallback(&"hand", 1.0, size, rules)
	check_approx(hand.x, size.x * rules.hand_side, "hand side")
	check_approx(hand.y, size.y * rules.hand_height, "hand height")
	var tiny: Vector3 = ModelAnchors.fallback(&"chest", 1.0, Vector2(0.5, 0.0), rules)
	check_approx(tiny.y, rules.fallback_height * rules.chest_height, "an empty height falls back")


func test_pixel_anchors_use_the_rules_shares() -> void:
	var rules := ContentDB.get_def("visual_rules", &"default") as VisualRulesDef
	var visual := CharacterVisual.new()
	visual.source_kind = &"pixel"
	tree.root.add_child(visual)
	visual.set_sprite(&"rydan")
	var hand: Vector3 = visual.source.anchor(&"hand")
	check_approx(hand.y, visual.height() * rules.pixel_hand_height, "pixel hand height")
	check_approx(hand.x, visual.width() * rules.hand_side, "pixel hand reach")
	var belt: Vector3 = visual.source.anchor(&"belt")
	check_approx(belt.x, visual.width() * rules.belt_side, "pixel belt side")
	check_approx(belt.y, visual.height() * rules.belt_height, "pixel belt height")
	visual.free()


func test_a_missing_anchor_key_is_a_content_error() -> void:
	var errors := PackedStringArray()
	var def := VisualRulesDef.new()
	def.read(DefReader.new({"id": "default"}, "t", errors))
	var text: String = "\n".join(errors)
	check(text.contains("chest_height: missing") and text.contains("fallback_height: missing"), text)


func check_approx(val: float, target: float, msg: String) -> void:
	check(absf(val - target) <= 0.0001, "%s: expected %f got %f" % [msg, target, val])
