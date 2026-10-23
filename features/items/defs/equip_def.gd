class_name EquipDef
extends Def
## Shared base of everything a hero can wear or wield (hilt, blade, prosthetic): names, a rarity tier and an
## optional perk (Rare and above only; rules in docs/design/prosthetics.md). Subclasses call read_gear() first.

var name_key: String = ""
var desc_key: String = ""
var rarity: StringName = &""
## A PerkDef id, or empty.
var perk: StringName = &""
## Stat adds per upgrade level (e.g. {"attack": 2} or {"max_hp": 15, "defense": 1}).
var upgrade: Dictionary[StringName, int] = {}


func read_gear(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	desc_key = r.text("desc_key")
	rarity = r.id("rarity")
	perk = StringName(r.text("perk", "", false))
	upgrade.clear()
	if r.has("upgrade"):
		var u: DefReader = r.child("upgrade")
		for stat_name: String in ["max_hp", "defense", "attack", "agility", "sp", "hp", "knockback"]:
			if u.has(stat_name):
				upgrade[StringName(stat_name)] = u.integer(stat_name, -999, 9999, 0, false)


## The references every piece of gear has: its rarity and, when set, its perk.
func gear_references() -> Array[Array]:
	var out: Array[Array] = [["rarity", rarity]]
	if perk != &"":
		out.append(["perk", perk])
	return out


## "" when the item's perk (if any) is allowed at its rarity tier; else the reason. Only tiers with
## allows_perk (Rare and above) may carry one.
func perk_problem(tier: RarityDef) -> String:
	if perk != &"" and not tier.allows_perk:
		return "'%s' is %s but has perk '%s' (Rare and above only)" % [id, rarity, perk]
	return ""
