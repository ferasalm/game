// Rain over the cold-open frames: thin slanted streaks in two layers at two speeds, tinted faintly green (acid).
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.75, 0.95, 0.8, 0.35);
uniform float speed = 1.6;
uniform float density = 110.0;
uniform float slant = 0.18;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

float streaks(vec2 uv, float dens, float spd) {
	uv.x += uv.y * slant;
	float column = floor(uv.x * dens);
	float r = hash(column);
	float y = fract(uv.y * 0.8 - TIME * spd * (0.6 + r) + r * 7.0);
	float drop = smoothstep(0.0, 0.03, y) * (1.0 - smoothstep(0.03, 0.16, y));
	float line = 1.0 - smoothstep(0.0, 0.12, abs(fract(uv.x * dens) - 0.5));
	return drop * line * step(0.6, r);
}

void fragment() {
	float a = streaks(UV, density, speed) + 0.6 * streaks(UV + vec2(0.37, 0.0), density * 1.7, speed * 0.7);
	COLOR = vec4(tint.rgb, tint.a * clamp(a, 0.0, 1.0));
}
