shader_type spatial;
// The painted world surface (painted looks only; the unpainted look keeps StandardMaterial3D): a painted or
// pixel texture, either on the mesh UVs (facade atlases) or world-space triplanar (tiles, so strokes stay square
// across blocks), times vertex colours and a tint, an optional emission map (lit windows), lit by the shared
// painted light model with its min_light floor. Fragments in the camera's cut-away tube dither away.
render_mode diffuse_lambert, specular_disabled;
#include "res://features/world/view/shaders/painted_light.gdshaderinc"
#include "res://features/world/view/shaders/occlusion_dither.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D emission_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = true;
uniform bool use_triplanar = false;
uniform bool use_vertex_color = false;
uniform bool use_emission = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float triplanar_scale = 0.25;
uniform float triplanar_sharpness = 8.0;
uniform float emission_energy = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec4 triplanar(sampler2D tex) {
	vec3 p = world_pos * triplanar_scale * vec3(1.0, -1.0, 1.0);
	vec3 w = pow(abs(world_normal), vec3(triplanar_sharpness));
	w /= max(w.x + w.y + w.z, 0.0001);
	return texture(tex, p.zy) * w.x + texture(tex, p.xz) * w.y + texture(tex, p.xy) * w.z;
}

void fragment() {
	occlusion_dither(world_pos, FRAGCOORD.xy);  // the camera cut-away
	vec3 colour = tint.rgb;
	if (use_texture) {
		colour *= use_triplanar ? triplanar(albedo_tex).rgb : texture(albedo_tex, UV).rgb;
	}
	if (use_vertex_color) {
		// Vertex colours are palette sRGB values (StandardMaterial3D's vertex_color_is_srgb).
		vec3 c = COLOR.rgb;
		colour *= mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045)));
	}
	ALBEDO = colour;
	ROUGHNESS = 1.0;
	vec3 glow = use_emission ? texture(emission_tex, UV).rgb * emission_energy : vec3(0.0);
	EMISSION = glow + painted_floor(colour);
}

void light() {
	painted_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, DIFFUSE_LIGHT);
}
