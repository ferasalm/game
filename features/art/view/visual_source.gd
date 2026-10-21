class_name VisualSource
extends RefCounted
## What draws a CharacterVisual. The facade owns the node tree and the world position; a source owns the picture:
## PixelSource (a lit pixel-art quad, today's look) or PuppetSource (cut painted parts, later). Every method here
## is a harmless no-op so a source only overrides what it can do. A source never touches the scene outside the
## nodes it adds under visual.body.

## A one-shot clip reached a named frame: &"impact" (the hit lands) or &"end" (the clip is over).
signal clip_event(event: StringName)

var visual: CharacterVisual
var rules: VisualRulesDef


func attach(owner_visual: CharacterVisual, owner_rules: VisualRulesDef) -> void:
	visual = owner_visual
	rules = owner_rules


## Shows the picture with this content id (a pixel sprite id; a puppet id later).
func set_sprite(_sprite_id: StringName) -> void:
	pass


## 1.0 faces right, -1.0 faces left.
func set_flip(_facing: float) -> void:
	pass


## Every frame: poses the body for the walk / idle state.
func update(_delta: float, _moving: bool, _prop: bool, _down: bool, _facing: float) -> void:
	pass


## A root move has begun: &"anticipate", &"dash", &"impact", &"hurt", &"turn", &"flash".
func cue(_kind: StringName) -> void:
	pass


## Starts a one-shot clip for a battle state (attack, cast, hurt, victory, item) and emits its clip events.
func play_clip(_state: StringName, _facing: float) -> void:
	pass


## Crouch and hold while a spell leaves. Callers await it.
func cast_pose(_hold: float) -> void:
	pass


## Victory hop. Callers await it.
func hop() -> void:
	pass


func set_down(_down: bool, _animate: bool) -> void:
	pass


func tint_down(_share: float) -> void:
	pass


func height() -> float:
	return 0.0


func width() -> float:
	return 0.0


## Where a spot of the body is, in metres relative to the visual's origin (its feet): &"feet", &"hand", &"head".
func anchor(_which: StringName) -> Vector3:
	return Vector3.ZERO
