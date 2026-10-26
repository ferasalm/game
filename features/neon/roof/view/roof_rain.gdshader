shader_type canvas_item;

uniform vec4 rain_color : source_color = vec4(0.7, 0.85, 1.0, 0.28);
uniform float speed : hint_range(0.5, 10.0) = 4.0;
uniform float slant : hint_range(-1.0, 1.0) = -0.22;
uniform float density : hint_range(10.0, 120.0) = 55.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	uv.x += uv.y * slant;
	vec2 st = vec2(uv.x * density, uv.y * (density * 0.15) - TIME * speed);
	vec2 ipos = floor(st);
	vec2 fpos = fract(st);
	float h = hash(ipos);
	float streak = step(0.91, h) * smoothstep(0.0, 0.15, fpos.y) * smoothstep(1.0, 0.75, fpos.y);
	float width = 1.0 - abs(fpos.x - 0.5) * 2.0;
	float alpha = clamp(streak * width * rain_color.a * 2.5, 0.0, 1.0);
	COLOR = vec4(rain_color.rgb, alpha);
}
