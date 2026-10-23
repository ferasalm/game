shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

uniform vec4 grid_color : source_color = vec4(0.2392, 0.9412, 0.8784, 0.85);
uniform float grid_spacing = 0.15;
uniform float disc_radius = 1.05;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float dist = length(world_pos.xz);
	if (dist > disc_radius) {
		discard;
	}
	float rim_fade = clamp((disc_radius - dist) / (disc_radius * 0.75), 0.0, 1.0);
	rim_fade = smoothstep(0.0, 1.0, rim_fade);

	vec2 coord = world_pos.xz / grid_spacing;
	vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float line = 1.0 - clamp(min(grid.x, grid.y) - 0.5, 0.0, 1.0);

	float alpha = line * rim_fade * grid_color.a;
	ALBEDO = grid_color.rgb;
	ALPHA = alpha;
}
