shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec2 blur_center = vec2(0.5, 0.5);
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	if (blur_amount <= 0.001) {
		COLOR = texture(screen_texture, SCREEN_UV);
	} else {
		vec2 dir = blur_center - SCREEN_UV;
		vec4 sum = vec4(0.0);
		const float SAMPLES = 10.0;
		for (float i = 0.0; i < SAMPLES; i += 1.0) {
			float scale = 1.0 - blur_amount * (i / SAMPLES) * 0.45;
			vec2 uv = blur_center - dir * scale;
			sum += texture(screen_texture, uv);
		}
		COLOR = sum / SAMPLES;
	}
}
