class_name VfxDef
extends Def
## One battle effect kind (content/combat/vfx.json, id = an ActionDef.VFX_KINDS entry): when the hit lands,
## the hitstop and camera shake / push it earns, and the layers of pooled sprites it paints. Layers are data:
## texture, anchors, size, colour, timing, drift. Colour times `energy` can exceed 1 so the night bloom picks it up.

const TEXTURES: Array[StringName] = [
	&"arc", &"ring", &"glow", &"streak", &"hex", &"spark", &"mote", &"bolt0", &"bolt1", &"bolt2", &"line", &"net"]
## actor / target (their middle), feet / head (of the target), hand (in front of the actor), mid (actor to target).
const ANCHORS: Array[StringName] = [&"actor", &"target", &"feet", &"head", &"hand", &"mid"]

## Seconds from the start until the hit lands (damage numbers, flash and recoil wait for it).
var impact: float = 0.0
## Freeze frames at the impact, camera shake, and a push-in toward the attacker (0 = none).
var hitstop: float = 0.0
var shake: float = 0.0
var zoom: float = 0.0
## How far a hit pushes the target back (metres); 0 = it only flashes and shakes.
var knock: float = 0.0
var layers: Array[VfxLayer] = []


func read(r: DefReader) -> void:
	id = r.id()
	impact = r.number("impact", 0.0, 3.0)
	hitstop = r.number("hitstop", 0.0, 1.0, 0.0, false)
	shake = r.number("shake", 0.0, 2.0, 0.0, false)
	zoom = r.number("zoom", 0.0, 1.0, 0.0, false)
	knock = r.number("knock", 0.0, 3.0, 0.0, false)
	for layer_reader: DefReader in r.objects("layers"):
		var layer := VfxLayer.new()
		layer.read(layer_reader)
		layers.append(layer)
	if layers.is_empty():
		r.problem("layers", "an effect needs at least one layer")
