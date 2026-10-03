shader_type canvas_item;

uniform vec4 paper_color : source_color = vec4(1.0, 0.84, 0.30, 1.0);
uniform float spacing = 9.0;

void fragment() {
	float dots = 1.0 - step(0.11, length(fract(FRAGCOORD.xy / spacing) - vec2(0.5)));
	COLOR = vec4(paper_color.rgb * (1.0 - dots * 0.12), 1.0);
}
