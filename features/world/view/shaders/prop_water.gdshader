shader_type spatial;
// Painted water for props (the sabil's basin and its stream): unshaded, no textures. Faces that look up show slow
// crossing ripples in three flat paint bands plus glints; upright faces (the falling stream) show bright dashes
// running down. Boosted past 1 so the night bloom picks the glints up. Joins the camera cut-away.
render_mode unshaded;
#include "res://features/world/view/shaders/occlusion_dither.gdshaderinc"

uniform vec3 deep_color : source_color = vec3(0.12, 0.43, 0.53);
uniform vec3 light_color : source_color = vec3(0.35, 0.82, 1.0);
uniform vec3 glint_color : source_color = vec3(0.9, 1.0, 1.0);
uniform float ripple_scale : hint_range(0.5, 12.0) = 5.0;
uniform float ripple_speed : hint_range(0.0, 4.0) = 1.0;
uniform float fall_scale : hint_range(1.0, 30.0) = 9.0;
uniform float fall_speed : hint_range(0.0, 12.0) = 4.0;
uniform float glint_amount : hint_range(0.0, 1.0) = 0.12;
uniform float boost : hint_range(0.5, 4.0) = 1.5;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	occlusion_dither(world_pos, FRAGCOORD.xy);
	float t = TIME * ripple_speed;
	float wave;
	if (world_normal.y > 0.5) {
		vec2 p = world_pos.xz * ripple_scale;
		wave = sin(p.x * 1.7 + t * 1.6) * sin(p.y * 1.9 - t * 1.3) + 0.5 * sin((p.x + p.y) * 2.9 + t * 2.4);
		wave = wave * 0.33 + 0.5;
	} else {
		float lane = sin(world_pos.x * 83.0 + world_pos.z * 57.0);
		wave = fract(world_pos.y * fall_scale + TIME * fall_speed + lane * 0.5);
	}
	float band = floor(clamp(wave, 0.0, 0.999) * 3.0) / 2.0;
	vec3 colour = mix(deep_color, light_color, band);
	float glint = step(1.0 - glint_amount, wave);
	ALBEDO = (colour + glint_color * glint) * boost;
}
