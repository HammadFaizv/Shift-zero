shader_type canvas_item;

uniform sampler2D light_map : filter_nearest, repeat_disable;
uniform sampler2D burn_map : filter_linear, repeat_disable;
uniform vec4 light_uv_rect;
uniform float hidden_threshold = 0.30;
uniform float visible_threshold = 0.55;
uniform vec4 ink_color : source_color = vec4(0.165, 0.122, 0.361, 1.0);
uniform float hidden_opacity = 0.792;
uniform float murky_opacity = 0.36;
uniform float print_mix = 0.0;
uniform float posterize_steps = 5.0;
uniform float color_boost = 2.4;
uniform float comic_brightness = 1.25;
uniform float edge_strength = 2.2;
uniform float edge_threshold = 0.13;
uniform float halftone_spacing = 5.0;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void fragment() {
	vec3 photo = texture(TEXTURE, UV).rgb;
	float light = texture(light_map, light_uv_rect.xy + UV * light_uv_rect.zw).r;
	vec3 raw = photo * mix(0.40, 1.0, clamp(light, 0.0, 1.0));
	float preview_alpha = light < hidden_threshold ? hidden_opacity : (light < visible_threshold ? murky_opacity : 0.0);
	raw = mix(raw, ink_color.rgb, preview_alpha);
	float grey = lum(photo);
	vec3 comic = clamp(mix(vec3(grey), photo, color_boost) * comic_brightness, 0.0, 1.0);
	comic = floor(comic * posterize_steps + 0.5) / posterize_steps;
	vec2 step_uv = TEXTURE_PIXEL_SIZE * edge_strength;
	float dx = abs(lum(texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).rgb) - lum(texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).rgb));
	float dy = abs(lum(texture(TEXTURE, UV + vec2(0.0, step_uv.y)).rgb) - lum(texture(TEXTURE, UV - vec2(0.0, step_uv.y)).rgb));
	comic = mix(comic, vec3(0.07, 0.08, 0.16), smoothstep(edge_threshold, edge_threshold * 2.0, dx + dy));
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	float dot_mask = 1.0 - step(0.14, length(fract(px / halftone_spacing) - vec2(0.5)));
	comic *= 1.0 - dot_mask * 0.15;
	if (light < hidden_threshold) {
		comic = mix(comic, ink_color.rgb, hidden_opacity);
	} else if (light < visible_threshold) {
		float density = mix(0.7, 0.15, (light - hidden_threshold) / (visible_threshold - hidden_threshold));
		float stripe = step(fract((px.x + px.y) / halftone_spacing), density);
		comic = mix(comic, ink_color.rgb, stripe);
	}
	vec3 printed = mix(raw, comic, print_mix);
	float burn = texture(burn_map, light_uv_rect.xy + UV * light_uv_rect.zw).r;
	printed = mix(printed, mix(vec3(0.33, 0.15, 0.06), vec3(0.025, 0.018, 0.025), burn), burn);
	COLOR = vec4(printed, 1.0);
}
