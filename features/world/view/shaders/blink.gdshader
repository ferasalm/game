shader_type spatial;
render_mode unshaded, fog_disabled;
// A beacon: vertex colour pulsing on and off `rate` times a second. The phase comes from the instance's position,
// so a row of beacons does not blink together. Dim (not off) between pulses.

uniform float rate = 0.8;
uniform float boost = 2.4;

varying float phase;

void vertex() {
	vec2 p = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xz;
	phase = fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = fract(TIME * rate + phase);
	float on = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.18, 0.3, t));
	ALBEDO = COLOR.rgb * (0.12 + boost * on);
}
