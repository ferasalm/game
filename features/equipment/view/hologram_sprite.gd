class_name HologramSprite
extends RefCounted
## purpose: The still a 2D menu hologram shows: a hero's Neon idle sprite facing the camera, or their portrait.

const STATE: StringName = &"idle"


## The idle sheet's row 6 (toward the camera), frame 0, or the hero's portrait when there is no Neon sprite set.
static func texture_for(hero: StringName) -> Texture2D:
	var sprite_set := ContentDB.get_def("neon_sprite_set", hero) as NeonSpriteSetDef
	if sprite_set != null:
		var idle: NeonSpriteState = sprite_set.get_state(STATE)
		if idle != null:
			var sheet: Texture2D = load(idle.sheet) as Texture2D
			if sheet != null:
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(
					Vector2(0.0, float(IsoDir.TOWARD_CAMERA) * float(idle.frame_size.y)),
					Vector2(idle.frame_size))
				return atlas
	return Portraits.texture(hero, &"neutral")
