class_name Progression
extends RefCounted
## Pure RPG progression rules: level calculation from XP thresholds, stat growth from class definitions,
## XP awards to party members, and encounter XP calculation. Never mutates input objects.

static var default_levels: LevelsDef = null
static var default_classes: Dictionary[StringName, ClassDef] = {}


## The level reached for a given XP amount, capped at the size of the threshold list (LevelsDef.xp_total).
static func level(xp_amount: int, levels_def: LevelsDef = null) -> int:
	var def: LevelsDef = levels_def if levels_def != null else default_levels
	if def == null or def.xp_total.is_empty() or xp_amount <= 0:
		return 1
	var cap: int = def.xp_total.size()
	for i: int in range(cap - 1, -1, -1):
		if xp_amount >= def.xp_total[i]:
			return mini(i + 1, cap)
	return 1


## Returns a new CombatantDef with class growth stats applied for levels above 1.
static func grow(base: CombatantDef, class_def: ClassDef, hero_level: int) -> CombatantDef:
	if base == null:
		return null
	var out: CombatantDef = base.clone()
	if class_def == null or hero_level <= 1:
		return out
	var mult: int = hero_level - 1
	out.max_hp += class_def.growth.get(&"max_hp", 0) * mult
	out.max_sp += class_def.growth.get(&"max_sp", 0) * mult
	out.attack += class_def.growth.get(&"attack", 0) * mult
	out.defense += class_def.growth.get(&"defense", 0) * mult
	out.agility = clampi(out.agility + class_def.growth.get(&"agility", 0) * mult, CombatantDef.AGILITY_MIN, CombatantDef.AGILITY_MAX)
	out.luck = clampi(out.luck + class_def.growth.get(&"luck", 0) * mult, 0, 99)
	return out


## Awards XP to every hero in the party, updating the xp dictionary and returning an array of LevelUp.
static func award(
		xp_dict: Dictionary, party: Array, amount: int,
		levels_def: LevelsDef = null, classes: Dictionary = {}) -> Array[LevelUp]:
	var def: LevelsDef = levels_def if levels_def != null else default_levels
	var class_map: Dictionary = classes if not classes.is_empty() else default_classes
	var out: Array[LevelUp] = []
	for hero: Variant in party:
		var hero_id := StringName(str(hero))
		var old_xp: int = int(xp_dict.get(hero_id, 0))
		var old_lv: int = level(old_xp, def)
		var new_xp: int = old_xp + amount
		xp_dict[hero_id] = new_xp
		var new_lv: int = level(new_xp, def)
		if new_lv > old_lv:
			var lu := LevelUp.new()
			lu.hero = hero_id
			lu.from_level = old_lv
			lu.to_level = new_lv
			var diff: int = new_lv - old_lv
			var c_def: ClassDef = class_map.get(hero_id) as ClassDef
			if c_def != null:
				for stat: StringName in c_def.growth:
					lu.gains[stat] = c_def.growth[stat] * diff
			out.append(lu)
	return out


## Total XP an encounter yields: sum of its enemies' XP.
static func encounter_xp(encounter: EncounterDef, combatants: Dictionary = {}) -> int:
	if encounter == null:
		return 0
	var total: int = 0
	for enemy_id: StringName in encounter.enemies:
		var enemy: CombatantDef = combatants.get(enemy_id) as CombatantDef
		if enemy != null:
			total += enemy.xp
	return total
