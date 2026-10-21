class_name RarityDef
extends Def
## One rarity tier: its name, display colour, sort order, whether it is story-only (never loot) and whether
## gear of this tier may carry a perk. Tiers are hand-made fixed items; there are no random rolls.

var name_key: String = ""
var colour: Color = Color.WHITE
var order: int = 0
var story_only: bool = false
var allows_perk: bool = false


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	var hex: String = r.text("colour")
	if Color.html_is_valid(hex):
		colour = Color.html(hex)
	else:
		r.problem("colour", "'%s' is not a hex colour" % hex)
	order = r.integer("order", 0, 99)
	story_only = r.flag("story_only")
	allows_perk = r.flag("allows_perk")
