shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

uniform vec4 rim_color : source_color = vec4(0.0, 0.95, 0.95, 0.85);
uniform float rim_power : hint_range(0.5, 6.0) = 2.5;
uniform float scanline_speed : hint_range(0.0, 10.0) = 3.0;
uniform float scanline_density : hint_range(1.0, 250.0) = 100.0;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float scanline = sin((VERTEX.y + TIME * scanline_speed) * scanline_density) * 0.5 + 0.5;
	float scan_bright = smoothstep(0.35, 0.85, scanline);
	vec3 col = rim_color.rgb * (fresnel * 0.75 + scan_bright * 0.35);
	ALBEDO = col;
	ALPHA = rim_color.a * clamp(fresnel * 0.8 + scan_bright * 0.4, 0.0, 1.0);
}
