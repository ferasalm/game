class_name PauseLogic
extends RefCounted
## Pure rules of the pause menu: which entries show and in what order, which ask "are you sure", the vitals of a
## hero with a missing record (= full), and the play-time clock text. No nodes, no autoloads.

const RESUME: StringName = &"resume"
const ITEMS: StringName = &"items"
const EQUIPMENT: StringName = &"equipment"
const LOAD_LAST: StringName = &"load_last"
const RESTART: StringName = &"restart"
const UNSTUCK: StringName = &"unstuck"
const TITLE: StringName = &"title"
const QUIT: StringName = &"quit"

## id -> [label key, confirm body key ("" = no question)]
const ENTRIES: Dictionary[StringName, Array] = {
	RESUME: ["PAUSE_RESUME", ""],
	ITEMS: ["PAUSE_ITEMS", ""],
	EQUIPMENT: ["PAUSE_EQUIPMENT", ""],
	LOAD_LAST: ["PAUSE_LOAD_LAST", "PAUSE_CONFIRM_LOAD"],
	RESTART: ["PAUSE_RESTART", "PAUSE_CONFIRM_RESTART"],
	UNSTUCK: ["PAUSE_UNSTUCK", "PAUSE_CONFIRM_UNSTUCK"],
	TITLE: ["PAUSE_TITLE", "PAUSE_CONFIRM_TITLE"],
	QUIT: ["PAUSE_QUIT", "PAUSE_CONFIRM_QUIT"],
}
const SECONDS_PER_MINUTE: int = 60
const SECONDS_PER_HOUR: int = 3600


## The entries to show, top to bottom. Items and Equipment need their screens registered; the fourth entry is
## "Load last save" when a save exists and "Restart" when none does.
static func entries(has_items: bool, has_equipment: bool, has_save: bool) -> Array[StringName]:
	var out: Array[StringName] = [RESUME]
	if has_items:
		out.append(ITEMS)
	if has_equipment:
		out.append(EQUIPMENT)
	out.append(LOAD_LAST if has_save else RESTART)
	out.append_array([UNSTUCK, TITLE, QUIT])
	return out


static func label_key(entry: StringName) -> String:
	return ENTRIES[entry][0] if ENTRIES.has(entry) else ""


## The question text key for an entry, "" when it acts at once.
static func confirm_key(entry: StringName) -> String:
	return ENTRIES[entry][1] if ENTRIES.has(entry) else ""


## HP and SP of a hero from a vitals dictionary {hero: {hp, sp}}; a missing record means full.
static func vitals_of(vitals: Variant, hero: StringName, max_hp: int, max_sp: int) -> Vector2i:
	if not (vitals is Dictionary):
		return Vector2i(max_hp, max_sp)
	var record: Variant = (vitals as Dictionary).get(hero, (vitals as Dictionary).get(String(hero)))
	if not (record is Dictionary):
		return Vector2i(max_hp, max_sp)
	var data: Dictionary = record
	return Vector2i(clampi(int(data.get("hp", max_hp)), 0, max_hp), clampi(int(data.get("sp", max_sp)), 0, max_sp))


## "HH:MM:SS" of a play time in seconds (negative or missing counts as zero).
static func clock(seconds: Variant) -> String:
	var total: int = maxi(int(seconds) if seconds != null else 0, 0)
	return "%02d:%02d:%02d" % [total / SECONDS_PER_HOUR, (total % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE,
			total % SECONDS_PER_MINUTE]


## Whole riyal for display; a missing value counts as zero.
static func money_of(value: Variant) -> int:
	return maxi(int(value) if value != null else 0, 0)
