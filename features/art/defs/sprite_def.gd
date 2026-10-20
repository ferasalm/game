class_name SpriteDef
extends Def
## One pixel sprite: rows of palette letters ('.' = transparent), all the same width, feet on the last row.

var palette: StringName = &""
var rows: PackedStringArray = PackedStringArray()
var source: String = ""
var licence: String = ""


func read(r: DefReader) -> void:
	id = r.id()
	palette = r.id("palette")
	rows = r.text_list("rows")
	source = r.text("source")
	licence = r.text("licence")


func width() -> int:
	return rows[0].length() if not rows.is_empty() else 0


func height() -> int:
	return rows.size()


func references() -> Array[Array]:
	return [["palette", palette]]
