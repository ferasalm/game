shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.2392, 0.9412, 0.8784, 0.15);
uniform float line_spacing : hint_range(1.0, 30.0) = 6.0;
uniform float line_thickness : hint_range(1.0, 10.0) = 3.0;
uniform float speed : hint_range(0.0, 200.0) = 45.0;

void fragment() {
	float y = FRAGCOORD.y + TIME * speed;
	float mod_y = mod(y, line_spacing);
	float line = step(mod_y, line_thickness);
	COLOR = vec4(line_color.rgb, line_color.a * line);
}
