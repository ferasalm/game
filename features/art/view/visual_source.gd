class_name VisualSource
extends RefCounted
## What draws a CharacterVisual. The facade owns the node tree and the world position; a source owns the picture:
## PixelSource (a lit pixel-art quad, today's look) or ModelSource (a live 3D model). Every method here
## is a harmless no-op so a source only overrides what it can do. A source never touches the scene outside the
## nodes it adds under visual.body.

## A one-shot clip reached a named frame: &"impact" (the hit lands) or &"end" (the clip is over).
signal clip_event(event: StringName)

var visual: CharacterVisual
var rules: VisualRulesDef


func attach(owner_visual: CharacterVisual, owner_rules: VisualRulesDef) -> void:
	visual = owner_visual
	rules = owner_rules


## The painted materials of this source: the look feeds the shared light uniforms into each (PaintedLook).
func materials() -> Array[ShaderMaterial]:
	return []


## The facade swaps to another source: free the nodes this one added under visual.body.
func detach() -> void:
	pass


## Shows the picture with this content id (a pixel sprite id, or a model id).
func set_sprite(_sprite_id: StringName) -> void:
	pass


## 1.0 faces right, -1.0 faces left.
func set_flip(_facing: float) -> void:
	pass


## Eases the facing toward a direction on the ground (a model turns by yaw; a sprite only mirrors, via set_flip).
func face_dir(_dir: Vector3) -> void:
	pass


## Freezes the current clip for `seconds`, then lets it run on.
func hit_stop(_seconds: float) -> void:
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
