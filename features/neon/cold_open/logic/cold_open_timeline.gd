class_name ColdOpenTimeline
extends RefCounted
## purpose: Pure timing of the Roya cold open (docs/briefs/neon-cold-open.md): when each shot starts and how far its
## push has run, its fade and its caption's fade, the alert's fill on the last shot, the lock, the cut to black, the end.


static func shot_start(def: NeonColdOpenDef, index: int) -> float:
	var t: float = 0.0
	for i: int in index:
		t += def.shots[i]["seconds"] as float
	return t


## 0..1 opacity of a shot drawn over the earlier ones: it fades in over the crossfade (the first one from black).
static func shot_alpha(def: NeonColdOpenDef, index: int, t: float) -> float:
	var since: float = t - shot_start(def, index)
	if since < 0.0:
		return 0.0
	return clampf(since / maxf(def.crossfade, 0.001), 0.0, 1.0)


## 0..1 progress of a shot's slow push and pan; it keeps moving through the next shot's crossfade.
static func shot_progress(def: NeonColdOpenDef, index: int, t: float) -> float:
	var length: float = (def.shots[index]["seconds"] as float) + def.crossfade
	return clampf((t - shot_start(def, index)) / length, 0.0, 1.0)


## 0..1 caption opacity: fades in caption_delay after the shot starts, out caption_fade before it ends.
static func caption_alpha(def: NeonColdOpenDef, index: int, t: float) -> float:
	var start: float = shot_start(def, index) + def.caption_delay
	var end: float = shot_start(def, index) + (def.shots[index]["seconds"] as float)
	if index == def.shots.size() - 1:
		end = minf(end, cut_time(def))
	var fade_in: float = (t - start) / def.caption_fade
	var fade_out: float = (end - t) / def.caption_fade
	return clampf(minf(fade_in, fade_out), 0.0, 1.0)


static func alert_begin(def: NeonColdOpenDef) -> float:
	return shot_start(def, def.shots.size() - 1) + def.alert_start


## -1 before the alert shows, then 0..1 as it fills.
static func alert_fill(def: NeonColdOpenDef, t: float) -> float:
	var since: float = t - alert_begin(def)
	if since < 0.0:
		return -1.0
	return clampf(since / def.alert_fill, 0.0, 1.0)


static func lock_time(def: NeonColdOpenDef) -> float:
	return alert_begin(def) + def.alert_fill


static func cut_time(def: NeonColdOpenDef) -> float:
	return lock_time(def) + def.cut_after_lock


static func end_time(def: NeonColdOpenDef) -> float:
	return cut_time(def) + def.black_hold
