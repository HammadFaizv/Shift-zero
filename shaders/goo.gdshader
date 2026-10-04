shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, specular_schlick_ggx;
// A flat splat of green slime: a wobbly blob with a few flung droplets. `fade` 1 -> 0 dries it away.

uniform vec4 goo_color : source_color = vec4(0.36, 0.78, 0.16, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float seed = 0.0;
uniform int droplets = 9;

float hash(float n) { return fract(sin(n * 127.1 + seed * 31.7) * 43758.5453); }

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float edge = 0.44 + 0.06 * sin(a * 3.0 + seed) + 0.045 * sin(a * 5.0 + seed * 2.3) + 0.02 * sin(a * 9.0 + seed * 0.7);
	float blob = smoothstep(edge, edge - 0.05, r);
	float drops = 0.0;
	for (int i = 0; i < droplets; i++) {
		float fi = float(i);
		float angle = hash(fi) * 6.2831;
		float dist = 0.55 + 0.35 * hash(fi + 11.0);
		float size = 0.025 + 0.05 * hash(fi + 23.0);
		drops = max(drops, smoothstep(size, size * 0.55, length(p - vec2(cos(angle), sin(angle)) * dist)));
	}
	float mask = max(blob, drops);
	float depth = clamp(1.0 - r / max(edge, 0.01), 0.0, 1.0);
	ALBEDO = mix(goo_color.rgb * 0.55, goo_color.rgb * 1.15, depth);
	ROUGHNESS = 0.06;
	SPECULAR = 1.0;
	METALLIC = 0.0;
	EMISSION = goo_color.rgb * 0.12 * depth;
	ALPHA = mask * fade * 0.93;
}
