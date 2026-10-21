shader_type spatial;
// A painted character picture on a quad (look spike): turned toward the camera around the vertical axis like
// character.gdshader, linear filtered with mipmaps, alpha-cut with alpha-to-coverage edges, lit by the shared
// painted light, ringed by an ink line where the picture meets empty space, with a cool rim on its upper edges.
render_mode cull_disabled, diffuse_lambert, specular_disabled;
#include "res://features/world/view/shaders/painted_light.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float flip = 1.0;
uniform vec3 ink_color : source_color = vec3(0.1, 0.08, 0.125);
uniform float ink_px = 3.0;
uniform vec3 edge_rim_color : source_color = vec3(0.55, 0.7, 1.0);
uniform float edge_rim = 0.35;

void vertex() {
	vec3 right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up = MODEL_MATRIX[1].xyz;
	vec3 forward = normalize(cross(right, normalize(up)));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(right * length(MODEL_MATRIX[0].xyz), 0.0), vec4(up, 0.0),
		vec4(forward * length(MODEL_MATRIX[2].xyz), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

// The lowest alpha in a ring of ink_px texels: below 1 means the pixel sits on the figure's edge.
float ring_alpha(vec2 uv, vec2 texel) {
	float a = 1.0;
	for (int k = 0; k < 8; k++) {
		float t = float(k) * TAU / 8.0;
		a = min(a, texture(albedo_tex, uv + vec2(cos(t), sin(t)) * texel * ink_px).a);
	}
	return a;
}

void fragment() {
	vec2 uv = vec2(flip > 0.0 ? UV.x : 1.0 - UV.x, UV.y);
	vec4 px = texture(albedo_tex, uv);
	vec2 texel = 1.0 / vec2(textureSize(albedo_tex, 0));
	float ink = 1.0 - smoothstep(0.35, 0.9, ring_alpha(uv, texel));
	float top = 1.0 - texture(albedo_tex, uv + vec2(-0.7, -0.7) * texel * ink_px * 2.0).a;
	vec3 colour = mix(px.rgb, ink_color, ink);
	ALBEDO = colour;
	ALPHA = px.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA_ANTIALIASING_EDGE = 0.3;
	ROUGHNESS = 1.0;
	EMISSION = painted_floor(colour) + edge_rim_color * edge_rim * top * (1.0 - ink) * paint_mix;
}

void light() {
	painted_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, DIFFUSE_LIGHT);
}
