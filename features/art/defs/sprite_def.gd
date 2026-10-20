class_name SpriteDef
extends Def
## One pixel sprite: rows of palette letters ('.' = transparent), all the same width, feet on the last row.
## pixels_per_metre: its own texel density (0 = the visual rules' default; stand-ins drawn at 16 keep their size).

var palette: StringName = &""
var rows: PackedStringArray = PackedStringArray()
var source: String = ""
var licence: String = ""
var pixels_per_metre: float = 0.0


func read(r: DefReader) -> void:
	id = r.id()
	palette = r.id("palette")
	rows = r.text_list("rows")
	source = r.text("source")
	licence = r.text("licence")
	pixels_per_metre = r.number("pixels_per_metre", 0.0, 128.0, 0.0, false)


func width() -> int:
	return rows[0].length() if not rows.is_empty() else 0


func height() -> int:
	return rows.size()


func references() -> Array[Array]:
	return [["palette", palette]]
