extends Reference
class_name VectorHex

# Uses the "Doubled Coordinates" system for Hexagonal coordinates
const doublewidth_direction_vectors = [
	Vector2(+1, -1), Vector2(+2,  0), 
	Vector2(+1, +1), Vector2(-1,  +1), 
	Vector2(-2, 0), Vector2(-1, -1), 
]

var x : int
var y : int

func _init(_x : int, _y : int):
	var hex_cords = grid_to_hex_cords(_x, _y)
	x = int(hex_cords.x)
	y = int(hex_cords.y)


func get_neighbor(direction) -> Vector2:
	return to_vector2() + doublewidth_direction_vectors[int(direction)]


func to_vector2() -> Vector2:
	return Vector2(x, y)


func to_grid_cords() -> Vector2:
	return Vector2(x / 2, y)


func to_world_pos() -> Vector3:
	var grid_cords = to_grid_cords()
	return HexMetrics.cell_world_pos(grid_cords.x, grid_cords.y)


static func grid_to_hex_cords(_x, _y) -> Vector2:
	var doubledwidth = 2 * _x if _y % 2 == 0 else (2 * _x) + 1
	return Vector2(doubledwidth, _y)


static func distance(a, b) -> float:
	var dcol = abs(a.x - b.x)
	var drow = abs(a.y - b.y)
	return drow + max(0, (dcol-drow)/2) / 2


func _to_string():
	return "%s, %s" % [x, y]
