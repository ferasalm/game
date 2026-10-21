shader_type spatial;
// The ink outline: a full-screen quad (painted looks) that draws dark ink where the depth or the normals jump
// (Sobel on the depth and normal-roughness buffers). render_priority -128 puts it first among transparent things,
// so mist, effects, Label3D text and neon draw over the ink. The depth threshold grows with distance (no lines on
// gently sloped far roofs) and the ink fades with the same exponential curve as the environment fog, so there is
// no dark halo against the fogged distance or the sky.
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled, blend_mix;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform vec3 ink_color : source_color = vec3(0.1, 0.08, 0.125);
uniform float strength : hint_range(0.0, 1.0) = 0.85;
uniform float width : hint_range(0.0, 4.0) = 1.0;
uniform float depth_threshold = 0.04;
uniform float normal_threshold = 0.5;
uniform float threshold_grow = 0.04;
uniform float fog_density = 0.01;
uniform float max_distance = 120.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	float d = texture(depth_tex, uv).x;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -view.z / view.w;
}

vec3 view_normal(vec2 uv) {
	return texture(normal_tex, uv).xyz * 2.0 - 1.0;
}

void fragment() {
	vec2 px = width / VIEWPORT_SIZE;
	float centre = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float gx = 0.0;
	float gy = 0.0;
	vec3 nx = vec3(0.0);
	vec3 ny = vec3(0.0);
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			if (i == 0 && j == 0) {
				continue;
			}
			vec2 uv = SCREEN_UV + vec2(float(i), float(j)) * px;
			float wx = float(i) * (j == 0 ? 2.0 : 1.0);
			float wy = float(j) * (i == 0 ? 2.0 : 1.0);
			float d = min(linear_depth(uv, INV_PROJECTION_MATRIX), max_distance);
			gx += d * wx;
			gy += d * wy;
			vec3 n = view_normal(uv);
			nx += n * wx;
			ny += n * wy;
		}
	}
	float near_depth = min(centre, max_distance);
	float depth_edge = length(vec2(gx, gy)) / max(near_depth, 0.001);
	float threshold = depth_threshold * (1.0 + near_depth * threshold_grow);
	float edge_d = smoothstep(threshold, threshold * 2.0, depth_edge);
	float edge_n = smoothstep(normal_threshold, normal_threshold * 1.6, sqrt(dot(nx, nx) + dot(ny, ny)));
	float fog = exp(-fog_density * near_depth);
	float sky = step(centre, max_distance);
	ALBEDO = ink_color;
	ALPHA = clamp(max(edge_d, edge_n), 0.0, 1.0) * strength * fog * sky;
}
