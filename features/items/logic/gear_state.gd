class_name GearState
extends RefCounted
## Holds all worn gear, progression level, socketed stones, upgrades, and perks for building a hero fighter.

var level: int = 1
var base: CombatantDef = null
var class_def: ClassDef = null
var armor: ArmorDef = null
var hilt: HiltDef = null
var blade: BladeDef = null
var prosthetic: ProstheticDef = null
var socketed_stones: Array[StoneDef] = []
var upgrades: Dictionary[StringName, int] = {}
var perks: Dictionary[StringName, PerkDef] = {}
