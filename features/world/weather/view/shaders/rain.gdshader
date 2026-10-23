shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;
// Additive rain streak that cuts off at the floor death threshold.

uniform vec4 rain_color : source_color = vec4(0.72, 0.82, 0.94, 0.32);
uniform float floor_death_y = -2.0;

varying float v_world_y;

void vertex() {
	v_world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	if (v_world_y < floor_death_y) {
		discard;
	}
	float streak = smoothstep(0.0, 0.12, UV.y) * smoothstep(1.0, 0.82, UV.y);
	float width_fade = 1.0 - abs(UV.x - 0.5) * 2.0;
	ALBEDO = rain_color.rgb;
	ALPHA = streak * width_fade * rain_color.a;
}
