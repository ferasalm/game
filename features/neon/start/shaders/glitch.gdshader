shader_type canvas_item;

uniform float glitch_strength : hint_range(0.0, 1.0) = 0.0;
uniform float glitch_offset : hint_range(0.0, 0.2) = 0.04;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	if (glitch_strength <= 0.001) {
		COLOR = base;
	} else {
		float offset = glitch_strength * glitch_offset;
		vec4 right = texture(TEXTURE, vec2(UV.x + offset, UV.y)) * COLOR;
		vec4 left = texture(TEXTURE, vec2(UV.x - offset, UV.y)) * COLOR;
		float r = right.r;
		float g = base.g;
		float b = left.b;
		float a = max(base.a, max(right.a, left.a));
		COLOR = vec4(r, g, b, a);
	}
}
