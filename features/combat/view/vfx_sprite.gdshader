shader_type spatial;
// One effect quad: unshaded, additive, drawn over everything. The colour (HDR, so the night bloom picks it up)
// comes per instance, the picture per material. `soft` picks smooth sampling for glows, nearest for pixel art.
render_mode unshaded, blend_add, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D tex_pixel : source_color, filter_nearest;
uniform sampler2D tex_soft : source_color, filter_linear;
uniform float soft = 0.0;
instance uniform vec4 tint = vec4(1.0);

void fragment() {
	vec4 px = mix(texture(tex_pixel, UV), texture(tex_soft, UV), soft);
	ALBEDO = px.rgb * tint.rgb;
	ALPHA = px.a * tint.a;
}
