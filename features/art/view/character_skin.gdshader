shader_type spatial;
// A live 3D character (body, hair, garments, the hilt): one painted albedo times a tint, lit by the SAME painted light
// as the world (painted_light.gdshaderinc: soft bands, indigo shadow tint, rim), plus a guaranteed floor of light so
// a figure never goes black against the moon. No normal or roughness maps, no specular. The ink outline is the
// screen-space pass of the look (it reads this mesh's depth and normals); `outline_hull` models add a second
// inverted-hull pass (character_hull.gdshader). Extras kept from the pixel facade: hit flash, desaturation (knocked
// out), glow (revive) and the tint.
render_mode diffuse_lambert, specular_disabled;
#include "res://features/art/view/painted_light.gdshaderinc"

/** The painted albedo (soft light and cavity darkening baked in). White when a part has no texture. */
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
/** Neon and glass glow mask: white = glows with emit_color. Black when the model has none. */
uniform sampler2D emit_tex : source_color, filter_linear_mipmap, hint_default_black;
/** Multiplies the albedo: skin tone, uniform colour, cloth colour. */
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 emit_color : source_color = vec3(1.0, 0.6, 0.3);
uniform float emit_amount : hint_range(0.0, 8.0) = 1.0;
uniform vec3 flash_color : source_color = vec3(1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float desat : hint_range(0.0, 1.0) = 0.0;
uniform vec3 glow_color : source_color = vec3(0.4, 1.0, 0.7);
uniform float glow = 0.0;

void fragment() {
	vec3 colour = texture(albedo_tex, UV).rgb * tint.rgb * COLOR.rgb;  // code-built parts paint with vertex colours
	colour = mix(colour, vec3(dot(colour, vec3(0.299, 0.587, 0.114))), desat);
	ALBEDO = mix(colour, flash_color, flash);
	ROUGHNESS = 1.0;
	EMISSION = painted_floor(colour) * (1.0 - flash) + glow_color * glow + flash_color * flash * 0.8
		+ emit_color * emit_amount * texture(emit_tex, UV).rgb;
}

void light() {
	painted_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, DIFFUSE_LIGHT);
}
