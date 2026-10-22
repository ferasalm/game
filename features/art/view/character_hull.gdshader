shader_type spatial;
// Inverted-hull ink line (next_pass of a character material, flag `outline_hull` of the ModelDef): the mesh again,
// pushed out along its normals and drawn from the inside only, in flat ink. For thin parts the screen-space outline
// loses against a wall (the jambiyah, a scarf). Costs one more pass over the mesh, so it is off by default.
render_mode unshaded, cull_front, shadows_disabled;

uniform vec3 ink_color : source_color = vec3(0.1, 0.08, 0.125);
/** How far the shell stands off the mesh, in metres. */
uniform float hull_width : hint_range(0.0, 0.05) = 0.012;

void vertex() {
	VERTEX += NORMAL * hull_width;
}

void fragment() {
	ALBEDO = ink_color;
}
