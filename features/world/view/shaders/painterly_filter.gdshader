shader_type canvas_item;
// Route (a) of the painted-look comparison: a painterly screen filter over the whole picture. A 4-sector Kuwahara
// (each pixel blends its quadrants' means, the calmest weighted most, so flat areas turn into strokes and edges stay sharp), an ink
// line from the luminance edges, and a still paper grain. Cost: 4 x (radius + 1)^2 + 9 taps a pixel.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform int radius : hint_range(1, 6) = 4;
uniform float stroke_scale : hint_range(0.5, 3.0) = 1.3;
uniform vec3 ink_color : source_color = vec3(0.05, 0.035, 0.09);
uniform float ink_strength : hint_range(0.0, 1.0) = 0.7;
uniform float ink_threshold : hint_range(0.0, 2.0) = 0.45;
uniform float ink_softness : hint_range(0.01, 1.0) = 0.3;
uniform float paper : hint_range(0.0, 0.3) = 0.07;
uniform float paper_scale = 2.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec4 sector(vec2 uv, vec2 step_px, vec2 dir) {
	vec3 sum = vec3(0.0);
	vec3 sq = vec3(0.0);
	for (int j = 0; j <= radius; j++) {
		for (int i = 0; i <= radius; i++) {
			vec3 c = textureLod(screen_tex, uv + vec2(float(i), float(j)) * dir * step_px, 0.0).rgb;
			sum += c;
			sq += c * c;
		}
	}
	float n = float((radius + 1) * (radius + 1));
	vec3 mean = sum / n;
	vec3 v = abs(sq / n - mean * mean);
	return vec4(mean, v.r + v.g + v.b);
}

void fragment() {
	vec2 step_px = SCREEN_PIXEL_SIZE * stroke_scale;
	vec3 col = vec3(0.0);
	float total = 0.0;
	for (int k = 0; k < 4; k++) {
		vec2 dir = vec2(k % 2 == 0 ? -1.0 : 1.0, k < 2 ? -1.0 : 1.0);
		vec4 s = sector(SCREEN_UV, step_px, dir);
		float w = 1.0 / (0.00002 + s.a * s.a);
		col += s.rgb * w;
		total += w;
	}
	col /= total;
	vec2 e = SCREEN_PIXEL_SIZE * 1.5;
	float tl = luma(textureLod(screen_tex, SCREEN_UV + vec2(-e.x, -e.y), 0.0).rgb);
	float tr = luma(textureLod(screen_tex, SCREEN_UV + vec2(e.x, -e.y), 0.0).rgb);
	float bl = luma(textureLod(screen_tex, SCREEN_UV + vec2(-e.x, e.y), 0.0).rgb);
	float br = luma(textureLod(screen_tex, SCREEN_UV + vec2(e.x, e.y), 0.0).rgb);
	float l = luma(textureLod(screen_tex, SCREEN_UV + vec2(-e.x, 0.0), 0.0).rgb);
	float r = luma(textureLod(screen_tex, SCREEN_UV + vec2(e.x, 0.0), 0.0).rgb);
	float t = luma(textureLod(screen_tex, SCREEN_UV + vec2(0.0, -e.y), 0.0).rgb);
	float b = luma(textureLod(screen_tex, SCREEN_UV + vec2(0.0, e.y), 0.0).rgb);
	float gx = (tr + 2.0 * r + br) - (tl + 2.0 * l + bl);
	float gy = (bl + 2.0 * b + br) - (tl + 2.0 * t + tr);
	float edge = smoothstep(ink_threshold, ink_threshold + ink_softness, length(vec2(gx, gy)));
	float grain = value_noise(FRAGCOORD.xy / paper_scale) * 0.6 + value_noise(FRAGCOORD.xy / (paper_scale * 9.0)) * 0.4;
	float fibre = value_noise(FRAGCOORD.xy * vec2(0.08, 0.9));
	col *= 1.0 + (grain - 0.5) * paper * 2.0 + (fibre - 0.5) * paper * 0.6;
	col = mix(col, ink_color, edge * ink_strength);
	COLOR = vec4(col, 1.0);
}
