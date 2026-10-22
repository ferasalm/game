shader_type spatial;
// The arc smear card of a strike: a crescent (a disc minus a shifted disc) that sweeps in along its arc as `progress`
// goes 0 -> 1 and fades at the end. Turned toward the camera around the vertical axis (like the character quads);
// unlit, alpha-blended, no depth write, so it never hides what is behind it.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

/** Colour and strength of the smear (alpha is its peak opacity). */
uniform vec4 smear_color : source_color = vec4(1.0, 0.95, 0.8, 0.9);
/** 0 = not started, 1 = fully swept and gone. */
uniform float progress : hint_range(0.0, 1.0) = 0.0;
/** 1 sweeps left to right, -1 right to left (a card is never scaled negative). */
uniform float flip = 1.0;

void vertex() {
	vec3 right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 forward = normalize(cross(right, up));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(right * length(MODEL_MATRIX[0].xyz), 0.0),
		vec4(up * length(MODEL_MATRIX[1].xyz), 0.0),
		vec4(forward, 0.0), MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 * vec2(flip, 1.0);
	float outer = length(p);
	float inner = length(p - vec2(0.0, -0.32));
	float body = step(outer, 1.0) * step(0.92, inner);
	// The sweep runs along the arc: points are revealed by their angle, and the oldest part fades first.
	float angle = (atan(p.x, p.y) / PI) * 0.5 + 0.5;
	float revealed = smoothstep(angle - 0.15, angle, progress * 1.4);
	float fade = 1.0 - smoothstep(0.6, 1.0, progress);
	float edge = smoothstep(1.0, 0.7, outer);
	ALBEDO = smear_color.rgb;
	ALPHA = body * revealed * fade * smear_color.a * mix(0.55, 1.0, edge);
}
