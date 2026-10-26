shader_type canvas_item;
// purpose: The 0.3 s Neon battle start glitch: RGB split and scanlines over the map, strength 0..1.

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	float split = 0.008 * strength;
	vec3 colour;
	colour.r = texture(screen_tex, uv + vec2(split, 0.0)).r;
	colour.g = texture(screen_tex, uv).g;
	colour.b = texture(screen_tex, uv - vec2(split, 0.0)).b;
	float scan = 0.5 + 0.5 * sin(uv.y * 900.0);
	colour *= 1.0 - 0.3 * strength * scan;
	COLOR = vec4(colour, clamp(strength, 0.0, 1.0));
}
