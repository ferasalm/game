class_name PaletteDef
extends Def
## The locked colour palette: one letter per colour ("." is transparent and never listed here).

var colors: Dictionary[String, Color] = {}


func read(r: DefReader) -> void:
	id = r.id()
	var raw: Dictionary[String, String] = r.text_map("colors")
	for key: String in raw:
		if key.length() != 1 or key == ".":
			push_error("palette '%s': key '%s' must be one letter other than '.'" % [id, key])
		elif not Color.html_is_valid(raw[key]):
			push_error("palette '%s': '%s' is not a colour" % [id, raw[key]])
		else:
			colors[key] = Color.html(raw[key])
