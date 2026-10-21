shader_type canvas_item;
// The qamariya-glass shatter: the frame that was on screen breaks into coloured glass shards that tilt, drop and
// fade away, uncovering the live arena underneath. The screen is a grid of cells, each cut along one diagonal into two
// shards. A pixel looks at the cells around and above it (shards only fall), asks which shard now covers it by
// undoing that shard's move, and takes the frame colour from where the shard started. All numbers are uniforms.

uniform sampler2D frame : source_color, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 cells = vec2(10.0, 5.6);
uniform float fall = 1.5;
uniform float spread = 1.0;
uniform float spin = 2.5;
uniform float stagger = 0.45;
uniform float glass_amount = 0.35;
uniform float crack = 0.02;
uniform vec4 crack_color : source_color = vec4(0.02, 0.02, 0.05, 1.0);
uniform vec4 glass_0 : source_color = vec4(0.88, 0.27, 0.24, 1.0);
uniform vec4 glass_1 : source_color = vec4(0.95, 0.66, 0.23, 1.0);
uniform vec4 glass_2 : source_color = vec4(0.31, 0.75, 0.48, 1.0);
uniform vec4 glass_3 : source_color = vec4(0.25, 0.56, 0.88, 1.0);
uniform vec4 glass_4 : source_color = vec4(0.54, 0.35, 0.85, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec4 glass_of(float pick) {
	int i = int(floor(pick * 5.0));
	if (i == 0) return glass_0;
	if (i == 1) return glass_1;
	if (i == 2) return glass_2;
	if (i == 3) return glass_3;
	return glass_4;
}

mat2 rot(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat2(vec2(c, s), vec2(-s, c));
}

void fragment() {
	vec2 g = UV * cells;
	vec2 base = floor(g);
	float best_t = -1.0;
	vec4 best = vec4(0.0);
	float gap = crack * smoothstep(0.0, 0.06, progress);
	for (int dy = -5; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			vec2 cell = base + vec2(float(dx), float(dy));
			if (cell.x < 0.0 || cell.y < 0.0 || cell.x >= cells.x || cell.y >= ceil(cells.y)) {
				continue;
			}
			vec2 centre = cell + 0.5;
			float split = hash(cell + 7.0) < 0.5 ? -1.0 : 1.0;
			float radial = distance(centre / cells, vec2(0.5)) / 0.7;
			for (int piece = 0; piece < 2; piece++) {
				float seed = hash(cell + float(piece) * 13.0);
				float delay = stagger * clamp(radial + (seed - 0.5) * 0.25, 0.0, 1.0);
				float t = clamp((progress - delay) / max(1.0 - stagger, 0.01), 0.0, 1.0);
				vec2 move = vec2((seed - 0.5) * 2.0 * spread * t, fall * cells.y * t * t);
				float angle = (hash(cell + float(piece) * 29.0) - 0.5) * 2.0 * spin * t;
				vec2 p = rot(-angle) * (g - centre - move);
				float k = (p.y - split * p.x) * (piece == 0 ? -1.0 : 1.0);
				float edge = min(min(0.5 - abs(p.x), 0.5 - abs(p.y)), k * 0.7071);
				if (edge > gap && t >= best_t) {
					best_t = t;
					vec3 src = texture(frame, (centre + p) / cells).rgb;
					vec4 tint = glass_of(seed);
					float wash = glass_amount * smoothstep(0.0, 0.5, t);
					vec3 col = mix(src, src * 0.55 + tint.rgb * 0.6, wash);
					col = mix(crack_color.rgb, col, smoothstep(gap, gap + 0.05, edge));
					best = vec4(col, 1.0 - smoothstep(0.55, 1.0, t));
				}
			}
		}
	}
	COLOR = best;
}
