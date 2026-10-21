shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
// Cheap mist layer: one scrolling seamless noise texture on a flat plane. Alpha fades where the plane meets
// geometry (needs the depth texture: Forward+ / Mobile; Compatibility has none and shows hard edges), near the
// camera, and toward the plane's edges. 1 texture sample + 1 depth sample per pixel.

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec3 mist_color : source_color;
uniform float opacity;
uniform float noise_scale;
uniform vec2 speed;
uniform float low;
uniform float high;
uniform float depth_fade;
uniform float near_fade;
uniform float edge_fade;

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 uv = world_xz * noise_scale + speed * noise_scale * TIME;
	float n = texture(noise_tex, uv).r * 0.65 + texture(noise_tex, uv * 2.3 + 0.37).r * 0.35;
	float patch = smoothstep(low, high, n);

	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_dist = -behind.z / behind.w;
	float intersect = clamp((scene_dist + VERTEX.z) / depth_fade, 0.0, 1.0);

	float near = clamp(-VERTEX.z / max(near_fade, 0.001), 0.0, 1.0);
	vec2 e = min(UV, 1.0 - UV) / edge_fade;
	float edge = clamp(min(e.x, e.y), 0.0, 1.0);

	ALBEDO = mist_color;
	ALPHA = opacity * patch * intersect * near * edge;
}
