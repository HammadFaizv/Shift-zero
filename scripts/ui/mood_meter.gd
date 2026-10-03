extends Control

@export var value: float = 0.0:
	set(next):
		value = next
		queue_redraw()
@export var animation_seconds: float = 0.85
@export var mood_colors: PackedColorArray = PackedColorArray([Color("ec7278"), Color("e6ab67"), Color("aaaac2"), Color("80c4b5"), Color("d6a5d2")])

var selected_band: int = 0


func animate(score: int, band: int) -> void:
	selected_band = band
	create_tween().tween_property(self, "value", float(score), animation_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var left := 16.0
	var width := maxf(size.x - left * 2.0, 1.0)
	for i in 100:
		var position := float(i) / 99.0 * 4.0
		var index := mini(int(position), 3)
		var color := mood_colors[index].lerp(mood_colors[index + 1], position - index)
		draw_rect(Rect2(left + width * i / 100.0, 4, width / 100.0 + 1, 9), color)
	var needle := left + width * value / 100.0
	draw_colored_polygon(PackedVector2Array([Vector2(needle, 15), Vector2(needle - 5, 21), Vector2(needle + 5, 21)]), NewsroomTheme.DARK)
	var names := ["Furious", "Suspicious", "Divided", "Charmed", "Adoring"]
	for i in 5:
		var centre := Vector2(left + width * float(i) / 4.0, 42)
		var color := mood_colors[i] if i == selected_band else mood_colors[i].lightened(0.5)
		draw_circle(centre, 10, color)
		draw_arc(centre, 11, 0, TAU, 24, NewsroomTheme.DARK, 1.0, true)
		draw_circle(centre + Vector2(-3, -2), 1.1, NewsroomTheme.DARK)
		draw_circle(centre + Vector2(3, -2), 1.1, NewsroomTheme.DARK)
		if i < 2:
			draw_arc(centre + Vector2(0, 7), 4, PI + 0.25, TAU - 0.25, 10, NewsroomTheme.DARK, 1.0, true)
		elif i == 2:
			draw_line(centre + Vector2(-4, 4), centre + Vector2(4, 4), NewsroomTheme.DARK, 1.0)
		else:
			draw_arc(centre, 5, 0.2, PI - 0.2, 10, NewsroomTheme.DARK, 1.0, true)
		var font := ThemeDB.fallback_font
		var text_width := font.get_string_size(names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(font, Vector2(clampf(centre.x - text_width / 2.0, 0, size.x - text_width), 69), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, NewsroomTheme.DARK)
