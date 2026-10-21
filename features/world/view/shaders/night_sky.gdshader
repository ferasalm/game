shader_type sky;
// Procedural night sky for old Sana'a: gradient + haze, hash stars with twinkle, a faint milky way, a big moon
// with a halo, two drifting cloud layers (dark bodies, moonlit edges) and the megacity glow on the horizon.
// Renderer: any (no textures, no raymarching, no depth). Cost is only paid on pixels the sky is visible on.
// Every uniform is filled from content/world/sky.json (SkyDef); the three vec3 directions come from its angles.

uniform vec3 zenith_color : source_color;
uniform vec3 horizon_color : source_color;
uniform vec3 haze_color : source_color;
uniform vec3 ground_color : source_color;
uniform float gradient_power;
uniform float haze_falloff;
uniform float haze_strength;

uniform vec3 star_cool_color : source_color;
uniform vec3 star_warm_color : source_color;
uniform float star_scale;
uniform float star_density;
uniform float star_size;
uniform float star_brightness;
uniform float star_twinkle_speed;
uniform float star_twinkle_depth;

uniform vec3 milky_way_color : source_color;
uniform vec3 milky_way_normal;
uniform float milky_way_strength;
uniform float milky_way_width;
uniform float milky_way_scale;

uniform vec3 moon_dir;
uniform vec3 moon_color : source_color;
uniform vec3 moon_halo_color : source_color;
uniform float moon_size;
uniform float moon_energy;
uniform float moon_mare_strength;
uniform float moon_crater_strength;
uniform float moon_halo_size;
uniform float moon_halo_strength;
uniform float moon_wide_halo_strength;

uniform vec3 cloud_dark_color : source_color;
uniform vec3 cloud_lit_color : source_color;
uniform float cloud_light_strength;
uniform float cloud_rim_width;
uniform float cloud1_scale;
uniform float cloud1_speed_x;
uniform float cloud1_speed_y;
uniform float cloud1_coverage;
uniform float cloud1_softness;
uniform float cloud1_opacity;
uniform float cloud2_scale;
uniform float cloud2_speed_x;
uniform float cloud2_speed_y;
uniform float cloud2_coverage;
uniform float cloud2_softness;
uniform float cloud2_opacity;

uniform vec3 glow_dir;
uniform vec3 glow_low_color : source_color;
uniform vec3 glow_high_color : source_color;
uniform float glow_sharpness;
uniform float glow_height;
uniform float glow_strength;
uniform float glow_all_round;

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

vec2 hash22(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	q += dot(q, q.yzx + 33.33);
	return fract((q.xx + q.yz) * q.zy);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < octaves; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

float band(vec3 d) {
	float across = dot(d, milky_way_normal);
	return exp(-(across * across) / (milky_way_width * milky_way_width));
}

// Stars live in a 3D hash grid scaled to the sphere; a star's radius never drops under one pixel (no shimmer).
vec3 stars(vec3 d, float density) {
	vec3 p = d * star_scale;
	vec3 cell = floor(p);
	vec3 h = hash33(cell);
	if (h.x > density) {
		return vec3(0.0);
	}
	vec3 jitter = (hash33(cell + 17.0) - 0.5) * 0.6;
	float dist = length(fract(p) - 0.5 - jitter);
	float px = length(fwidth(p));
	float radius = max(star_size, px);
	float disc = smoothstep(radius, 0.0, dist) * (star_size / radius);
	float magnitude = 0.12 + pow(h.y, 5.0);
	float twinkle = 1.0 - star_twinkle_depth * (0.5 + 0.5 * sin(TIME * star_twinkle_speed * (0.5 + h.z) + h.x * 628.0));
	return mix(star_cool_color, star_warm_color, h.z) * disc * magnitude * twinkle * star_brightness;
}

float voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float best = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash22(i + g);
			best = min(best, length(g + o - f));
		}
	}
	return best;
}

// Moon: a lit disc with limb darkening, dark maria and craters, plus a tight and a wide halo.
vec3 moon(vec3 d, float cloud_cover) {
	float c = dot(d, moon_dir);
	float ang = acos(clamp(c, -1.0, 1.0));
	vec3 halo = moon_halo_color * (moon_halo_strength * exp(-ang / moon_halo_size)
		+ moon_wide_halo_strength / (1.0 + pow(ang / (moon_halo_size * 3.0), 2.0)));
	vec3 col = halo * (1.0 - 0.6 * cloud_cover);
	if (ang < moon_size * 1.15) {
		vec3 t = normalize(cross(moon_dir, vec3(0.0, 1.0, 0.0)));
		vec3 b = cross(t, moon_dir);
		vec2 uv = vec2(dot(d, t), dot(d, b)) / moon_size;
		float r = length(uv);
		float limb = pow(max(1.0 - r * r, 0.0), 0.2);
		float mare = smoothstep(0.42, 0.62, fbm(uv * 1.6 + 3.1, 3)) * moon_mare_strength;
		float crater = (1.0 - smoothstep(0.0, 0.3, voronoi(uv * 5.0))) * moon_crater_strength;
		vec3 surface = moon_color * moon_energy * limb * (1.0 - mare - crater * 0.6);
		float edge = smoothstep(1.0, 0.93, r);
		col = mix(col, surface, edge * (1.0 - 0.85 * cloud_cover));
	}
	return col;
}

// One cloud layer on a plane above the viewer. Returns density in x, moon-facing rim light in y.
vec2 cloud_layer(vec3 d, float scale, vec2 speed, float coverage, float softness) {
	vec2 uv = d.xz / (d.y + 0.2) * scale + speed * TIME;
	float dens = smoothstep(coverage, coverage + softness, fbm(uv, 3));
	vec2 toward = normalize(moon_dir.xz + 1e-4) * cloud_rim_width;
	float dens_moon = smoothstep(coverage, coverage + softness, fbm(uv + toward, 3));
	float fade = smoothstep(0.0, 0.2, d.y);
	return vec2(dens * fade, clamp(dens - dens_moon, 0.0, 1.0) * fade);
}

void sky() {
	vec3 d = EYEDIR;
	float up = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, zenith_color, pow(up, gradient_power));
	col += haze_color * haze_strength * exp(-max(d.y, 0.0) * haze_falloff);
	col = mix(col, ground_color, smoothstep(0.0, -0.3, d.y));

	// Megacity glow: orange at the horizon turning magenta higher up, strongest toward glow_dir.
	float az = max(dot(normalize(d.xz + 1e-5), normalize(glow_dir.xz)), 0.0);
	float lift = max(d.y, 0.0);
	vec3 glow_col = mix(glow_low_color, glow_high_color, clamp(lift / (glow_height * 2.0), 0.0, 1.0));
	col += glow_col * glow_strength * (pow(az, glow_sharpness) + glow_all_round) * exp(-lift / glow_height);

	// Clouds first: stars and the moon are hidden behind their density.
	vec2 c1 = cloud_layer(d, cloud1_scale, vec2(cloud1_speed_x, cloud1_speed_y), cloud1_coverage, cloud1_softness);
	vec2 c2 = cloud_layer(d, cloud2_scale, vec2(cloud2_speed_x, cloud2_speed_y), cloud2_coverage, cloud2_softness);
	float a1 = c1.x * cloud1_opacity;
	float a2 = c2.x * cloud2_opacity;
	float cover = 1.0 - (1.0 - a1) * (1.0 - a2);

	float mw = band(d);
	float mw_noise = 0.35 + 0.65 * fbm(d.xz * milky_way_scale + d.y * 3.7, 2);
	float horizon_fade = smoothstep(0.0, 0.25, d.y);
	col += milky_way_color * milky_way_strength * mw * mw_noise * horizon_fade * (1.0 - cover);
	col += stars(d, star_density * (1.0 + 3.0 * mw)) * horizon_fade * (1.0 - cover);
	col += moon(d, cover);

	float near_moon = pow(max(dot(d, moon_dir), 0.0), 6.0);
	vec3 lit = cloud_lit_color * cloud_light_strength;
	vec3 glow_under = glow_col * glow_strength * pow(az, glow_sharpness) * exp(-lift / glow_height) * 0.6;
	vec3 body1 = mix(cloud_dark_color + glow_under, lit, clamp(c1.y * 2.0 + near_moon * 0.2, 0.0, 1.0));
	vec3 body2 = mix(cloud_dark_color + glow_under, lit, clamp(c2.y * 2.0 + near_moon * 0.2, 0.0, 1.0));
	col = mix(col, body2, a2);
	col = mix(col, body1, a1);
	COLOR = col;
}
