class_name Gear
extends RefCounted
## Builds a hero's fighter from base stats, class level growth, armor, weapons, prosthetic,
## socketed gemstones, item upgrades, and perks. Never mutates the base CombatantDef.


## New full hero builder following the merge order of rpg-systems.md section 7:
## base -> level growth -> armor -> hilt -> blade -> pistol (frame, barrel) -> stones (hilt and ring sockets)
## -> prosthetic -> upgrades -> perks -> caps.
static func build_hero(hero_id: StringName, state: GearState) -> CombatantDef:
	var out: CombatantDef = state.base.clone() if state.base != null else CombatantDef.new()
	if state.class_def != null and state.level > 1:
		out = Progression.grow(out, state.class_def, state.level)
	_apply_armor(out, state)
	_apply_hilt(out, state)
	_apply_blade(out, state)
	_apply_pistol(out, state)
	_apply_stones(out, state)
	_apply_prosthetic(out, hero_id, state)
	_apply_upgrades(out, state)
	out = _apply_all_perks(out, state)
	_apply_caps(out)
	return out


## Backward-compatible thin wrapper around build_hero.
static func build(
		base: CombatantDef, hilt: HiltDef, blade: BladeDef, prosthetic: ProstheticDef,
		perks: Dictionary[StringName, PerkDef]) -> CombatantDef:
	var state := GearState.new()
	state.base = base
	state.hilt = hilt
	state.blade = blade
	state.prosthetic = prosthetic
	state.perks = perks
	return build_hero(base.id if base != null else &"", state)


static func _apply_armor(out: CombatantDef, state: GearState) -> void:
	if state.armor != null:
		out.max_hp += state.armor.max_hp
		out.defense += state.armor.defense
		out.agility += state.armor.agility
		out.weight += state.armor.weight


static func _apply_hilt(out: CombatantDef, state: GearState) -> void:
	if state.hilt != null:
		out.agility += state.hilt.agility
		out.cast_speed *= state.hilt.cast_speed
		out.weight += state.hilt.weight
		if state.hilt.ability != &"" and not out.actions.has(state.hilt.ability):
			out.actions.append(state.hilt.ability)


static func _apply_blade(out: CombatantDef, state: GearState) -> void:
	if state.blade != null:
		out.attack += state.blade.attack
		out.knockback_bonus += state.blade.knockback
		out.weight += state.blade.weight


## The rivet pistol frame merges like a hilt (agility, cast speed, weight, granted move), the barrel like
## a blade (attack, knockback, weight). Only the matching part is applied, whichever hero wears them.
static func _apply_pistol(out: CombatantDef, state: GearState) -> void:
	if state.frame != null:
		out.agility += state.frame.agility
		out.cast_speed *= state.frame.cast_speed
		out.weight += state.frame.weight
		if state.frame.ability != &"" and not out.actions.has(state.frame.ability):
			out.actions.append(state.frame.ability)
	if state.barrel != null:
		out.attack += state.barrel.attack
		out.knockback_bonus += state.barrel.knockback
		out.weight += state.barrel.weight


static func _apply_stones(out: CombatantDef, state: GearState) -> void:
	var worn: Array[StoneDef] = []
	worn.append_array(state.socketed_stones)
	worn.append_array(state.accessory_stones)
	for stone: StoneDef in worn:
		if stone != null:
			out.max_hp += stone.stats.get(&"hp", stone.stats.get(&"max_hp", 0))
			out.max_sp += stone.stats.get(&"sp", stone.stats.get(&"max_sp", 0))
			out.attack += stone.stats.get(&"attack", 0)
			out.defense += stone.stats.get(&"defense", 0)
			out.agility += stone.stats.get(&"agility", 0)


static func _apply_prosthetic(out: CombatantDef, hero_id: StringName, state: GearState) -> void:
	if state.prosthetic != null and (state.prosthetic.wearer == hero_id or state.prosthetic.wearer == out.id):
		out.max_hp += state.prosthetic.hp
		out.max_sp += state.prosthetic.sp
		out.attack += state.prosthetic.attack
		out.defense += state.prosthetic.defense
		out.agility += state.prosthetic.agility
		out.weight += state.prosthetic.weight
		for action_id: StringName in state.prosthetic.actions:
			if not out.actions.has(action_id):
				out.actions.append(action_id)


static func _apply_upgrades(out: CombatantDef, state: GearState) -> void:
	var worn: Array[EquipDef] = [state.armor, state.hilt, state.blade, state.frame, state.barrel, state.accessory, state.prosthetic]
	for item: EquipDef in worn:
		if item != null and "upgrade" in item:
			var up_level: int = state.upgrades.get(item.id, 0)
			if up_level > 0:
				var up: Dictionary = item.get("upgrade")
				out.max_hp += up.get(&"max_hp", up.get(&"hp", 0)) * up_level
				out.defense += up.get(&"defense", 0) * up_level
				out.attack += up.get(&"attack", 0) * up_level
				out.agility += up.get(&"agility", 0) * up_level


static func _apply_all_perks(out: CombatantDef, state: GearState) -> CombatantDef:
	var list: Array[PerkDef] = []
	var worn: Array[EquipDef] = [state.armor, state.hilt, state.blade, state.frame, state.barrel, state.accessory, state.prosthetic]
	list.append_array(Perks.of_items(worn, state.perks))
	for stone: StoneDef in state.socketed_stones:
		if stone != null and state.perks.has(stone.perk):
			list.append(state.perks[stone.perk])
	for stone: StoneDef in state.accessory_stones:
		if stone != null and state.perks.has(stone.perk):
			list.append(state.perks[stone.perk])
	if state.class_def != null and state.perks.has(state.class_def.passive):
		list.append(state.perks[state.class_def.passive])
	return Perks.apply(out, list)


static func _apply_caps(out: CombatantDef) -> void:
	out.agility = clampi(out.agility, CombatantDef.AGILITY_MIN, CombatantDef.AGILITY_MAX)
	out.cast_speed = clampf(out.cast_speed, CombatantDef.CAST_SPEED_MIN, CombatantDef.CAST_SPEED_MAX)
	out.max_hp = maxi(1, out.max_hp)
	out.max_sp = maxi(0, out.max_sp)
	out.attack = maxi(0, out.attack)
	out.defense = maxi(0, out.defense)
	out.weight = maxf(0.0, out.weight)
	out.luck = clampi(out.luck, 0, 99)
