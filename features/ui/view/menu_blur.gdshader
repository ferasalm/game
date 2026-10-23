shader_type canvas_item;
// Two box-blur passes (separable horizontal and vertical tent kernel convolution).

uniform float radius : hint_range(0.0, 32.0) = 6.0;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;
	vec4 sum = vec4(0.0);
	float total = 0.0;
	int r = int(radius);
	for (int x = -r; x <= r; x++) {
		for (int y = -r; y <= r; y++) {
			float weight = float((r + 1 - abs(x)) * (r + 1 - abs(y)));
			sum += texture(TEXTURE, UV + vec2(float(x), float(y)) * ps) * weight;
			total += weight;
		}
	}
	COLOR = total > 0.0 ? (sum / total) : texture(TEXTURE, UV);
}
