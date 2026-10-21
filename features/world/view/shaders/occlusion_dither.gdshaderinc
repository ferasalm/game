// The camera cut-away: whatever stands in a tube from the camera to the party dithers away (a noise screen-door,
// then the ink outline and the grade do the rest). OcclusionFade feeds the three global uniforms each frame:
// occ_cam = camera position (xyz) and the fade amount 0..1 (w); occ_target = the point on the party the camera looks
// at (xyz) and the tube radius (w); occ_shape = soft edge of the tube (x) and the last metres before the party that
// are never cut (y), and the height below which nothing is cut so the floor stays (z). Amount 0 (nothing in the way) costs one comparison. Same maths as SegmentBox.tube_weight.
global uniform vec4 occ_cam;
global uniform vec4 occ_target;
global uniform vec4 occ_shape;

void occlusion_dither(vec3 world, vec2 frag) {
	if (occ_cam.w <= 0.0) {
		return;
	}
	vec3 line = occ_target.xyz - occ_cam.xyz;
	float len = length(line);
	float along = dot(world - occ_cam.xyz, line) / max(len, 0.001);
	vec3 closest = occ_cam.xyz + line / max(len, 0.001) * clamp(along, 0.0, len);
	float across = distance(world, closest);
	float inside = 1.0 - smoothstep(occ_target.w, occ_target.w + occ_shape.x, across);
	float before = 1.0 - smoothstep(len - occ_shape.y - 1.0, len - occ_shape.y, along);
	float above = smoothstep(occ_shape.z, occ_shape.z + 0.4, world.y);
	float noise = fract(52.9829189 * fract(dot(frag, vec2(0.06711056, 0.00583715))));
	if (inside * before * above * occ_cam.w > noise) {
		discard;
	}
}
