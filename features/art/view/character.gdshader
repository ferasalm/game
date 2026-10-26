shader_type spatial;
// A pixel-art character quad: lit by the world lights, nearest-filtered, alpha-cut (so the moon casts its
// shadow), turned toward the camera around the vertical axis (a tilted node leans the figure as a shear).
// Extras over a plain sprite: hit flash, desaturation (knocked out), glow (revive), tint, mirroring.
render_mode cull_disabled, diffuse_lambert, specular_disabled;
// The shared painted light (paint_mix 0 = plain Lambert, the unpainted look).
#include "res://features/art/view/painted_light.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 flash_color : source_color = vec3(1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float desat : hint_range(0.0, 1.0) = 0.0;
uniform vec3 glow_color : source_color = vec3(0.4, 1.0, 0.7);
uniform float glow = 0.0;
uniform float flip = 1.0;
uniform float min_light : hint_range(0.0, 1.0) = 0.4;
uniform vec3 rim_color : source_color = vec3(0.5, 0.8, 1.0);
uniform float rim_amount = 0.5;

void vertex() {
	vec3 right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up = MODEL_MATRIX[1].xyz;
	vec3 forward = normalize(cross(right, normalize(up)));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(right * length(MODEL_MATRIX[0].xyz), 0.0), vec4(up, 0.0),
		vec4(forward * length(MODEL_MATRIX[2].xyz), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = vec2(flip > 0.0 ? UV.x : 1.0 - UV.x, UV.y);
	vec4 px = texture(albedo_tex, uv);
	if (px.a < 0.5) {
		discard;
	}
	vec3 colour = px.rgb * tint.rgb;
	colour = mix(colour, vec3(dot(colour, vec3(0.299, 0.587, 0.114))), desat);
	// Rim: opaque pixels that touch empty space above or beside them catch a cool moon-side light.
	vec2 step_uv = 1.0 / vec2(textureSize(albedo_tex, 0));
	float open_edge = 1.0 - min(1.0, texture(albedo_tex, uv + vec2(0.0, -step_uv.y)).a
		* texture(albedo_tex, uv + vec2(step_uv.x, 0.0)).a * texture(albedo_tex, uv - vec2(step_uv.x, 0.0)).a * 1.0);
	ALBEDO = mix(colour, flash_color, flash);
	// A guaranteed floor of brightness, so a figure never turns into a silhouette against the moon.
	EMISSION = colour * min_light * (1.0 - flash) + rim_color * rim_amount * open_edge
		+ glow_color * glow + flash_color * flash * 0.8;
	ROUGHNESS = 1.0;
}

void light() {
	painted_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, DIFFUSE_LIGHT);
}
