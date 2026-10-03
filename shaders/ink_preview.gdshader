shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;

uniform sampler2D light_map : filter_nearest, repeat_disable;
uniform sampler2D burn_map : filter_linear, repeat_disable;
uniform mat4 world_to_page;
uniform vec2 page_size;
uniform vec4 hidden_color : source_color = vec4(0.165, 0.122, 0.361, 1.0);
uniform float hidden_threshold;
uniform float visible_threshold;
uniform float hidden_opacity;
uniform float murky_opacity;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 local = (world_to_page * vec4(world_position, 1.0)).xyz;
	vec2 page_uv = local.xz / page_size + vec2(0.5);
	float light = texture(light_map, page_uv).r;
	ALBEDO = hidden_color.rgb;
	ALPHA = light < hidden_threshold ? hidden_opacity : (light < visible_threshold ? murky_opacity : 0.0);
	float burn = texture(burn_map, page_uv).r;
	if (burn > 0.0) {
		ALBEDO = mix(vec3(0.33, 0.15, 0.06), vec3(0.025, 0.018, 0.025), burn);
		ALPHA = max(ALPHA, burn);
	}
}
