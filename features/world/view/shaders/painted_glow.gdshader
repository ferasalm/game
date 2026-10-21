shader_type spatial;
// Unshaded vertex-colour glow of the painted world (neon strips, lit trims, far landmarks), boosted above 1 so it
// blooms; the same look as SurfaceMaterials.glow() but it joins the camera cut-away.
render_mode unshaded;
#include "res://features/world/view/shaders/occlusion_dither.gdshaderinc"

uniform float boost = 1.6;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	occlusion_dither(world_pos, FRAGCOORD.xy);
	vec3 c = COLOR.rgb;
	ALBEDO = mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045))) * boost;
}
