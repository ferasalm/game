class_name DefReader
extends RefCounted
## Typed, validated reads from one JSON object. Each failed read appends "<where>: <problem>" to errors
## and returns a safe default, so a loader can report every problem in a file at once.

var _data: Dictionary
var _where: String
var _errors: PackedStringArray


func _init(data: Dictionary, where: String, errors: PackedStringArray) -> void:
	_data = data
	_where = where
	_errors = errors


func id(key: String = "id") -> StringName:
	var value: String = text(key)
	if not value.is_empty() and (not value.is_valid_ascii_identifier() or value != value.to_lower()):
		_fail(key, "'%s' is not a lowercase_identifier" % value)
	return StringName(value)


func text(key: String, default: String = "", required: bool = true) -> String:
	if not _data.has(key):
		if required:
			_fail(key, "missing")
		return default
	if not (_data[key] is String):
		_fail(key, "not a string")
		return default
	return _data[key] as String


func number(key: String, min_value: float, max_value: float, default: float = 0.0, required: bool = true) -> float:
	if not _data.has(key):
		if required:
			_fail(key, "missing")
		return default
	if not (_data[key] is float or _data[key] is int):
		_fail(key, "not a number")
		return default
	var value: float = float(_data[key])
	if value < min_value or value > max_value:
		_fail(key, "%s outside %s..%s" % [_num(value), _num(min_value), _num(max_value)])
	return clampf(value, min_value, max_value)


func integer(key: String, min_value: int, max_value: int, default: int = 0, required: bool = true) -> int:
	return roundi(number(key, min_value, max_value, default, required))


func flag(key: String, default: bool = false) -> bool:
	if not _data.has(key):
		return default
	if not (_data[key] is bool):
		_fail(key, "not true/false")
		return default
	return _data[key] as bool


func id_list(key: String) -> Array[StringName]:
	var out: Array[StringName] = []
	if not _data.has(key):
		return out
	if not (_data[key] is Array):
		_fail(key, "not a list")
		return out
	for item: Variant in (_data[key] as Array):
		out.append(StringName(str(item)))
	return out


func text_list(key: String) -> PackedStringArray:
	var out := PackedStringArray()
	if not _data.has(key):
		_fail(key, "missing")
	elif not (_data[key] is Array):
		_fail(key, "not a list")
	else:
		for item: Variant in (_data[key] as Array):
			out.append(str(item))
	return out


## A {"key": "text"} object as a dictionary of String to String.
func text_map(key: String) -> Dictionary[String, String]:
	var out: Dictionary[String, String] = {}
	if not _data.has(key):
		_fail(key, "missing")
	elif not (_data[key] is Dictionary):
		_fail(key, "not an object")
	else:
		for name: Variant in (_data[key] as Dictionary):
			out[str(name)] = str((_data[key] as Dictionary)[name])
	return out


## A list of JSON objects as one reader each; errors name the element, e.g. "file[0].lines[2].key".
func objects(key: String) -> Array[DefReader]:
	var out: Array[DefReader] = []
	if not _data.has(key):
		_fail(key, "missing")
	elif not (_data[key] is Array):
		_fail(key, "not a list")
	else:
		var items: Array = _data[key] as Array
		for i: int in items.size():
			if items[i] is Dictionary:
				out.append(DefReader.new(items[i] as Dictionary, "%s.%s[%d]" % [_where, key, i], _errors))
			else:
				_fail("%s[%d]" % [key, i], "not an object")
	return out


## A string that must be one of options (an id such as an expression name).
func one_of(key: String, options: Array[StringName]) -> StringName:
	var value := StringName(text(key))
	if not options.has(value):
		_fail(key, "'%s' is not one of %s" % [value, options])
	return value
func int_list(key: String, min_value: int, max_value: int) -> Array[int]:
	var out: Array[int] = []
	if not _data.has(key):
		return out
	if not (_data[key] is Array):
		_fail(key, "not a list")
		return out
	for item: Variant in (_data[key] as Array):
		if not (item is float or item is int) or item < min_value or item > max_value:
			_fail(key, "'%s' is not a whole number in %d..%d" % [str(item), min_value, max_value])
		else:
			out.append(roundi(float(item)))
	return out


## Lets a Def report a rule that spans several keys.
func problem(key: String, what: String) -> void:
	_fail(key, what)


static func _num(value: float) -> String:
	return str(int(value)) if value == floorf(value) else str(value)


func _fail(key: String, problem: String) -> void:
	_errors.append("%s.%s: %s" % [_where, key, problem])


## A "#rrggbb" string as a Color (magenta, plus a problem, when it is wrong or required and missing).
func color(key: String, default: Color = Color.MAGENTA, required: bool = true) -> Color:
	if not required and not _data.has(key):
		return default
	var value: String = text(key)
	if not Color.html_is_valid(value):
		_fail(key, "'%s' is not a colour" % value)
		return Color.MAGENTA
	return Color.html(value)


## A list of JSON objects that may be absent (then empty); errors name the element like objects().
func optional_objects(key: String) -> Array[DefReader]:
	if not _data.has(key):
		return []
	return objects(key)


## A list of numbers that may be absent (then empty), each inside min_value..max_value.
func float_list(key: String, min_value: float, max_value: float) -> Array[float]:
	var out: Array[float] = []
	if not _data.has(key):
		return out
	if not (_data[key] is Array):
		_fail(key, "not a list")
		return out
	for item: Variant in (_data[key] as Array):
		if not (item is float or item is int) or float(item) < min_value or float(item) > max_value:
			_fail(key, "'%s' is not a number in %s..%s" % [str(item), _num(min_value), _num(max_value)])
		else:
			out.append(float(item))
	return out


## True when the key is present (for optional nested objects and lists).
func has(key: String) -> bool:
	return _data.has(key)
