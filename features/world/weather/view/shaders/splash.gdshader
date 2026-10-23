shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;
// Tiny ring flash ripple sprite that expands and fades on impact.

uniform vec4 splash_color : source_color = vec4(0.77, 0.86, 1.0, 0.4);

void fragment() {
	vec2 uv = (UV - vec2(0.5)) * 2.0;
	float d = length(uv);
	float ring = smoothstep(0.35, 0.72, d) * (1.0 - smoothstep(0.72, 0.98, d));
	ALBEDO = splash_color.rgb;
	ALPHA = ring * COLOR.a * splash_color.a;
}
