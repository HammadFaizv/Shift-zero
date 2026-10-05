extends Container
## Lays comic panels out on a 1-, 2-, 3- or 4-panel page so the whole page always
## fits the available box: no scrolling, and the photos are as large as they can be.
## Each child carries its width/height ratio in the "aspect" meta.

@export var gap: float = 10.0
@export var search_steps: int = 24
@export_range(1, 3) var columns: int = 2
@export var wide_last: bool = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout()


func _layout() -> void:
	var cells: Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			cells.append(child)
	if cells.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var rows := _rows(cells.size())
	var column_count := mini(columns, cells.size())
	# Largest base width s (one normal cell) whose page still fits the box.
	var low := 0.0
	var high := (size.x - gap * (column_count - 1)) / column_count
	for i in search_steps:
		var middle := (low + high) * 0.5
		if _height(cells, rows, middle) <= size.y:
			low = middle
		else:
			high = middle
	var base := low
	var y := (size.y - _height(cells, rows, base)) * 0.5
	for row in rows:
		var row_height := _row_height(cells, row, base)
		var row_width := 0.0
		for index in row:
			row_width += _width(cells, index, base) + (gap if index != row[0] else 0.0)
		var x := (size.x - row_width) * 0.5
		for index in row:
			var w := _width(cells, index, base)
			var h := w / _aspect(cells[index])
			fit_child_in_rect(cells[index], Rect2(x, y + (row_height - h) * 0.5, w, h))
			cells[index].pivot_offset = Vector2(w, h) * 0.5
			x += w + gap
		y += row_height + gap


func _rows(count: int) -> Array:
	var rows: Array = []
	for start in range(0, count, columns):
		rows.append(range(start, mini(start + columns, count)))
	return rows


func _aspect(cell: Control) -> float:
	return maxf(float(cell.get_meta("aspect", 1.0)), 0.01)


## The lone bottom panel of a three-panel page spans both columns.
func _width(cells: Array[Control], index: int, base: float) -> float:
	var spans := (wide_last or cells.size() == 3) and index == cells.size() - 1 and cells.size() % columns == 1
	return base * columns + gap * (columns - 1) if spans else base


func _row_height(cells: Array[Control], row: Array, base: float) -> float:
	var tallest := 0.0
	for index in row:
		tallest = maxf(tallest, _width(cells, index, base) / _aspect(cells[index]))
	return tallest


func _height(cells: Array[Control], rows: Array, base: float) -> float:
	var total := gap * (rows.size() - 1)
	for row in rows:
		total += _row_height(cells, row, base)
	return total
