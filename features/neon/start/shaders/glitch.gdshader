shader_type canvas_item;

uniform float glitch_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	if (glitch_strength <= 0.001) {
		COLOR = base;
	} else {
		float offset = glitch_strength * 0.04;
		float r = texture(TEXTURE, vec2(UV.x + offset, UV.y)).r;
		float g = base.g;
		float b = texture(TEXTURE, vec2(UV.x - offset, UV.y)).b;
		float a = max(base.a, max(texture(TEXTURE, vec2(UV.x + offset, UV.y)).a, texture(TEXTURE, vec2(UV.x - offset, UV.y)).a));
		COLOR = vec4(r, g, b, a);
	}
}
