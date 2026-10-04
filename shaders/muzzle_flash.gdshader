shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled;
// A four-point muzzle star with a hot core. Face the quad at the camera from script.

uniform float intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float spikes = pow(abs(cos(a * 2.0)), 10.0) * 0.55 + pow(abs(cos(a * 3.0 + 0.8)), 14.0) * 0.25;
	float star = max(0.0, 1.0 - r / (0.3 + spikes));
	float core = exp(-r * r * 14.0);
	ALBEDO = vec3(1.0, 0.82, 0.42) * (core * 1.6 + star) * intensity;
	ALPHA = 1.0;
}
