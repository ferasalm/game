// The shared painted light model (world, props and characters): call painted_light() from light().
// paint_mix 0 = plain Lambert (the unpainted look, unchanged), 1 = painted: the light falls in paint_bands flat
// bands with soft edges, the light is tinted, the shadow side gets a hue-shifted (indigo) lift instead of grey, and
// a rim catches the light on grazing edges. Works for directional and omni/spot lights (ATTENUATION carries the
// falloff and the shadow). The min_light floor is applied in fragment() by each shader (painted_floor()).

uniform float paint_mix : hint_range(0.0, 1.0) = 0.0;
uniform float paint_bands : hint_range(1.0, 8.0) = 3.0;
uniform float paint_band_soft : hint_range(0.0, 0.5) = 0.08;
uniform vec3 paint_light_tint : source_color = vec3(1.0);
uniform vec3 paint_shadow_tint : source_color = vec3(0.32, 0.3, 0.78);
uniform float paint_shadow_lift : hint_range(0.0, 1.0) = 0.15;
uniform vec3 paint_rim_color : source_color = vec3(0.6, 0.75, 1.0);
uniform float paint_rim : hint_range(0.0, 2.0) = 0.0;
uniform float paint_rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float paint_min_light : hint_range(0.0, 1.0) = 0.0;

// x in 0..1 quantised to flat bands; each step blends over a soft edge so bands read as brush strokes, not aliasing.
float painted_band(float x, float bands, float soft) {
	float b = clamp(x, 0.0, 1.0) * bands;
	float i = floor(b);
	float f = b - i;
	return min((i + smoothstep(0.5 - soft * 0.5, 0.5 + soft * 0.5, f)) / bands, 1.0);
}

// Adds one light's diffuse contribution: pass NORMAL, LIGHT, VIEW, LIGHT_COLOR (energy x PI), ATTENUATION and
// LIGHT_IS_DIRECTIONAL (a directional light lifts its cast shadows too; a lamp only within its reach).
void painted_light(vec3 n, vec3 l, vec3 v, vec3 light_color, float attenuation, bool directional,
		inout vec3 diffuse) {
	float ndl = clamp(dot(n, l), 0.0, 1.0);
	float lambert = ndl * attenuation;
	vec3 radiance = light_color / PI;
	if (paint_mix <= 0.0) {
		diffuse += radiance * lambert;
		return;
	}
	float lit = mix(lambert, painted_band(lambert, paint_bands, paint_band_soft), paint_mix);
	vec3 tinted = radiance * mix(vec3(1.0), paint_light_tint, paint_mix);
	float strength = max(max(radiance.r, radiance.g), radiance.b);
	vec3 shadow = paint_shadow_tint * strength * paint_shadow_lift * paint_mix * (1.0 - lit)
		* (directional ? 1.0 : min(attenuation * 4.0, 1.0));
	float rim = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), paint_rim_power) * smoothstep(-0.2, 0.4, dot(n, l));
	diffuse += tinted * lit + shadow + paint_rim_color * radiance * rim * paint_rim * paint_mix * attenuation;
}

// The brightness floor: a share of the albedo that is always shown (add to EMISSION), so figures never go black.
vec3 painted_floor(vec3 albedo) {
	return albedo * paint_min_light * paint_mix;
}
