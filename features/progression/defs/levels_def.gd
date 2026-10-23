class_name LevelsDef
extends Def
## Thresholds of total XP required to reach each level (content/progression/levels.json).
## Index 0 is Lv 1 (0 XP), index 1 is Lv 2, etc. Level cap is xp_total.size().

var xp_total: Array[int] = []


func read(r: DefReader) -> void:
	id = r.id()
	xp_total = r.int_list("xp_total", 0, 999999)
