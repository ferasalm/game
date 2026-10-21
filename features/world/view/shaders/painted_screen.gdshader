shader_type canvas_item;
// The painted grade's screen pass (under every menu): a Hades-like oval vignette, heavier at the bottom corners,
// and a still canvas grain (two octaves of value noise, like paper under the paint) that lifts and darkens the
// picture a little. The colour LUT itself is the Environment's colour correction (PaintedLook).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 vignette_color : source_color = vec3(0.02, 0.016, 0.05);
uniform float vignette : hint_range(0.0, 1.0) = 0.4;
uniform float softness : hint_range(0.05, 1.0) = 0.6;
uniform float grain : hint_range(0.0, 0.3) = 0.04;
uniform float grain_scale = 1.6;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

void fragment() {
	vec3 src = texture(screen_tex, SCREEN_UV).rgb;
	vec2 pixel = SCREEN_UV / SCREEN_PIXEL_SIZE / grain_scale;
	float n = value_noise(pixel) * 0.6 + value_noise(pixel * 0.31 + 17.0) * 0.4;
	src *= 1.0 + grain * (n - 0.5) * 2.0;
	vec2 c = (SCREEN_UV - vec2(0.5, 0.45)) * vec2(1.0, 1.15);
	float v = smoothstep(0.75 - softness * 0.5, 0.95, length(c) * 1.35);
	COLOR = vec4(mix(src, vignette_color, v * vignette), 1.0);
}
