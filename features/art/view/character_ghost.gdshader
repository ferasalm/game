shader_type spatial;
// The afterimage of a character in motion: the same figure as a flat, glowing, fading silhouette.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable;
uniform vec3 ghost_color : source_color = vec3(0.5, 1.0, 1.0);
uniform float flip = 1.0;
instance uniform float fade = 0.0;

void vertex() {
	vec3 right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up = MODEL_MATRIX[1].xyz;
	vec3 forward = normalize(cross(right, normalize(up)));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(right * length(MODEL_MATRIX[0].xyz), 0.0), vec4(up, 0.0),
		vec4(forward * length(MODEL_MATRIX[2].xyz), 0.0), MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = vec2(flip > 0.0 ? UV.x : 1.0 - UV.x, UV.y);
	float a = texture(albedo_tex, uv).a;
	ALBEDO = ghost_color * 2.0;
	ALPHA = a * fade;
}
