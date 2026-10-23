shader_type spatial;
render_mode blend_add, unshaded, cull_back;

uniform vec4 rim_color : source_color = vec4(0.2392, 0.9412, 0.8784, 0.85);
uniform float rim_power : hint_range(0.5, 6.0) = 2.2;
uniform float scanline_speed : hint_range(0.0, 200.0) = 45.0;
uniform float scanline_period : hint_range(1.0, 20.0) = 6.0;

void fragment() {
	float NdotV = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - NdotV, rim_power);
	float scan_phase = (FRAGCOORD.y + TIME * scanline_speed) * (6.2831853 / scanline_period);
	float scanline = sin(scan_phase) * 0.5 + 0.5;
	float scan_bright = smoothstep(0.25, 0.75, scanline);
	float brightness = 0.35 + 0.65 * fresnel + 0.25 * scan_bright;
	ALBEDO = rim_color.rgb * brightness;
	ALPHA = rim_color.a * clamp(0.5 + 0.5 * fresnel, 0.0, 1.0);
}
