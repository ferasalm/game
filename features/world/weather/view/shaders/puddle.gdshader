shader_type spatial;
render_mode depth_draw_opaque, cull_disabled;
// Wet floor puddle with low roughness, fake sky/neon reflection, and animated rain ripple rings.

uniform vec4 floor_tint : source_color = vec4(0.12, 0.15, 0.20, 1.0);
uniform float darken_factor = 0.65;
uniform float roughness = 0.08;
uniform vec4 sky_ambient : source_color = vec4(0.08, 0.11, 0.18, 1.0);
uniform vec4 neon_magenta : source_color = vec4(1.0, 0.11, 0.47, 1.0);
uniform vec4 neon_cyan : source_color = vec4(0.0, 0.83, 1.0, 1.0);
uniform float ripple_speed = 2.4;
uniform float ripple_frequency = 14.0;
uniform float ripple_fade_in : hint_range(0.01, 1.0) = 0.2;
uniform float ripple_wave_speed : hint_range(0.1, 5.0) = 0.7;
uniform float ripple_decay : hint_range(1.0, 50.0) = 16.0;
uniform float ripple_normal_weight : hint_range(0.01, 1.0) = 0.22;
uniform float ripple_antialias : hint_range(0.001, 1.0) = 0.025;

void fragment() {
	vec2 local = (UV - vec2(0.5)) * 2.0;
	float angle = atan(local.y, local.x);
	float shape_radius = 0.82 + 0.12 * sin(angle * 3.0 + 1.5) + 0.08 * cos(angle * 5.0 - 0.7);
	float dist = length(local) / shape_radius;
	if (dist > 1.0) {
		discard;
	}
	float edge_alpha = 1.0 - smoothstep(0.88, 1.0, dist);

	// Three animated concentric ripple rings in local space
	vec2 ripple_norm = vec2(0.0);
	vec2 c0 = vec2(-0.25, -0.15);
	vec2 c1 = vec2(0.28, 0.18);
	vec2 c2 = vec2(0.05, -0.28);
	float t0 = fract(TIME * ripple_speed * 0.45);
	float t1 = fract(TIME * ripple_speed * 0.45 + 0.37);
	float t2 = fract(TIME * ripple_speed * 0.45 + 0.73);

	vec2 d0 = local - c0;
	vec2 d1 = local - c1;
	vec2 d2 = local - c2;
	float l0 = length(d0);
	float l1 = length(d1);
	float l2 = length(d2);

	if (l0 > 0.01) {
		float fade0 = smoothstep(0.0, ripple_fade_in, t0) * (1.0 - t0);
		float ring_dist0 = abs(l0 - t0 * ripple_wave_speed);
		float fw0 = fwidth(ring_dist0);
		float aa0 = 1.0 - smoothstep(0.0, ripple_antialias, fw0);
		float w0 = sin(ring_dist0 * ripple_frequency) * exp(-ring_dist0 * ripple_decay) * fade0 * aa0;
		ripple_norm += (d0 / l0) * w0 * ripple_normal_weight;
	}
	if (l1 > 0.01) {
		float fade1 = smoothstep(0.0, ripple_fade_in, t1) * (1.0 - t1);
		float ring_dist1 = abs(l1 - t1 * ripple_wave_speed);
		float fw1 = fwidth(ring_dist1);
		float aa1 = 1.0 - smoothstep(0.0, ripple_antialias, fw1);
		float w1 = sin(ring_dist1 * ripple_frequency) * exp(-ring_dist1 * ripple_decay) * fade1 * aa1;
		ripple_norm += (d1 / l1) * w1 * ripple_normal_weight;
	}
	if (l2 > 0.01) {
		float fade2 = smoothstep(0.0, ripple_fade_in, t2) * (1.0 - t2);
		float ring_dist2 = abs(l2 - t2 * ripple_wave_speed);
		float fw2 = fwidth(ring_dist2);
		float aa2 = 1.0 - smoothstep(0.0, ripple_antialias, fw2);
		float w2 = sin(ring_dist2 * ripple_frequency) * exp(-ring_dist2 * ripple_decay) * fade2 * aa2;
		ripple_norm += (d2 / l2) * w2 * ripple_normal_weight;
	}

	NORMAL = normalize(NORMAL + vec3(ripple_norm.x, 0.0, ripple_norm.y));

	vec2 world_xz = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float neon_coord = sin(world_xz.x * 0.35 + world_xz.y * 0.25);
	vec3 neon_color = mix(neon_magenta.rgb, neon_cyan.rgb, neon_coord * 0.5 + 0.5);
	float smear = smoothstep(0.1, 0.8, sin(world_xz.x * 0.6 - world_xz.y * 0.4));
	vec3 fake_reflect = mix(sky_ambient.rgb, neon_color, smear * 0.45);

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 base_tint = floor_tint.rgb * darken_factor;

	ALBEDO = mix(base_tint, fake_reflect, fresnel * 0.75 + 0.2);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.85;
	ALPHA = edge_alpha;
}
