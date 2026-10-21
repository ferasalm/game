shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
// A fake light pool: a soft additive disc on a floor or wall. Instance colour = light colour; custom data =
// (flicker amount, flicker speed, phase 0..1, energy). One draw call for every pool in the area.

varying vec4 custom;

void vertex() {
	custom = INSTANCE_CUSTOM;
}

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float fall = pow(clamp(1.0 - r, 0.0, 1.0), 2.2);
	float t = TIME * custom.y + custom.z * 6.2831;
	float wobble = 0.5 + 0.25 * sin(t) + 0.25 * sin(t * 2.37 + custom.z * 11.0);
	float flick = 1.0 - custom.x * (1.0 - wobble);
	ALBEDO = COLOR.rgb * custom.w * flick;
	ALPHA = fall;
}
