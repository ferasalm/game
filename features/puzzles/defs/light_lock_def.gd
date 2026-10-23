class_name LightLockDef
extends Def
## purpose: Defines the qamariya light lock puzzle layout (windows, mirrors, and hint timings).

var windows: Array[LightLockWindow] = []
var mirrors: Array[LightLockMirror] = []
var lens_at: Vector3 = Vector3.ZERO
var hint_secs: Array[int] = []
var hint_keys: Array[StringName] = []

var _windows_by_id: Dictionary[StringName, LightLockWindow] = {}
var _mirrors_by_id: Dictionary[StringName, LightLockMirror] = {}


func read(r: DefReader) -> void:
	id = r.id()
	windows.clear()
	_windows_by_id.clear()
	for wr: DefReader in r.objects("windows"):
		var w := LightLockWindow.new()
		w.id = wr.id()
		var b: int = wr.integer("bits", 1, 7)
		if b < 1 or b > 7:
			wr.problem("bits", "bad bits value %d" % b)
		w.bits = b
		w.target = StringName(wr.text("target", "", false))
		w.at = Def.vec3(wr, "at")
		windows.append(w)
		_windows_by_id[w.id] = w

	mirrors.clear()
	_mirrors_by_id.clear()
	for mr: DefReader in r.objects("mirrors"):
		var m := LightLockMirror.new()
		m.id = mr.id()
		m.targets = mr.id_list("targets")
		if m.targets.size() != 4:
			mr.problem("targets", "!= 4 targets: found %d" % m.targets.size())
		m.start = mr.integer("start", 0, 3, 0, false)
		m.at = Def.vec3(mr, "at")
		mirrors.append(m)
		_mirrors_by_id[m.id] = m

	for w: LightLockWindow in windows:
		if not _valid_target(w.target):
			r.problem("windows", "target '%s' is no id" % w.target)
	for m: LightLockMirror in mirrors:
		for t: StringName in m.targets:
			if not _valid_target(t):
				r.problem("mirrors", "target '%s' is no id" % t)

	if r.has("lens"):
		var lr: DefReader = r.child("lens")
		lens_at = Def.vec3(lr, "at")

	hint_secs = r.int_list("hint_secs", 0, 3600)
	hint_keys = r.id_list("hint_keys")


func get_window(win_id: StringName) -> LightLockWindow:
	return _windows_by_id.get(win_id)


func get_mirror(mir_id: StringName) -> LightLockMirror:
	return _mirrors_by_id.get(mir_id)


func _valid_target(t: StringName) -> bool:
	return t == &"" or t == &"lens" or _mirrors_by_id.has(t)
