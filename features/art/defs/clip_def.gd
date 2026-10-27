class_name ClipDef
extends Def
## The timing of one model clip (an animation of the shared library): its length, whether it loops, and for a one-shot
## the Hades-style retiming (docs/archive/design-3d/characters-3d.md 4): the clip runs slow to `windup_t`, holds a beat, runs fast
## through the strike to `strike_end_t` (`impact_t` lands inside it) and eases out. ClipTiming turns this into
## time; the numbers are placeholders tuned on renders.

## The animation's name in the library (Quaternius "Universal Animation Library"); empty for a rigid model's timing.
var animation: String = ""
var seconds: float = 1.0
var loops: bool = false
## Seconds into the clip when the hit lands (-1 = no impact event), where the wind-up ends and the strike ends.
var impact_t: float = -1.0
var windup_t: float = 0.0
var strike_end_t: float = -1.0
var windup_rate: float = 1.0
var hold: float = 0.0
var strike_rate: float = 1.0
var recover_rate: float = 1.0
## Seconds to cross-fade in from the previous pose.
var blend: float = 0.1
## For a looping gait: the clip seconds where a foot touches the ground (ascending); each one sounds a footstep.
var contacts: Array[float] = []


func read(r: DefReader) -> void:
	id = r.id()
	animation = r.text("animation", "", false)
	seconds = r.number("seconds", 0.05, 30.0, 1.0)
	loops = r.flag("loops")
	impact_t = r.number("impact_t", -1.0, 30.0, -1.0, false)
	windup_t = r.number("windup_t", 0.0, 30.0, 0.0, false)
	strike_end_t = r.number("strike_end_t", -1.0, 30.0, -1.0, false)
	windup_rate = r.number("windup_rate", 0.1, 4.0, 1.0, false)
	hold = r.number("hold", 0.0, 1.0, 0.0, false)
	strike_rate = r.number("strike_rate", 0.1, 6.0, 1.0, false)
	recover_rate = r.number("recover_rate", 0.1, 4.0, 1.0, false)
	blend = r.number("blend", 0.0, 1.0, 0.1, false)
	contacts = r.float_list("contacts", 0.0, seconds)
	contacts.sort()
	if impact_t > seconds or windup_t > seconds or strike_end_t > seconds:
		r.problem("impact_t", "windup_t, impact_t and strike_end_t must lie inside the clip (%s s)" % seconds)
	if strike_end_t < 0.0:
		strike_end_t = maxf(impact_t, windup_t)
	if impact_t >= 0.0 and (impact_t < windup_t or impact_t > strike_end_t):
		r.problem("impact_t", "must lie between windup_t and strike_end_t")
