shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;

uniform vec4 water_color : source_color = vec4(0.37, 0.83, 0.88, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.6;
uniform float scroll_speed : hint_range(0.0, 20.0) = 0.3;

void fragment() {
	vec2 uv = UV + vec2(TIME * scroll_speed, 0.0);
	float ripple = sin((uv.x + uv.y) * 18.0) * 0.06;
	ALBEDO = water_color.rgb;
	ALPHA = clamp(alpha + ripple, 0.0, 1.0);
}
