extends Reference
class_name HexCell

var cords : VectorHex
var world_pos : Vector3
var color : Color
var elevation : int
var neighbors := []

func _init(_cords : VectorHex, _color : Color, _elevation = 0):
	cords = _cords
	color = _color
	elevation = _elevation
	world_pos = cords.to_world_pos()
	neighbors.resize(6)

func _ready():
	pass


func get_neighbor(direction) -> HexCell:
	return neighbors[int(direction)]


func set_neighbor(direction, cell : HexCell):
	if cell == null:
		printerr("Cell %s cannot set neighbor to null" % cords.to_string())
		return
	neighbors[int(direction)] = cell
	cell.neighbors[HexMetrics.opposite_direction(direction)] = self
	
func get_neighbor_colors() -> Dictionary:
	var colors := {}
	for dir in neighbors.size():
		if get_neighbor(dir) != null:
			colors[dir] = neighbors[dir].color
	return colors


func get_edge_type(direction):
	if direction is get_script():
		return HexMetrics.get_edge_type(elevation, direction.elevation)
	var neighbor = get_neighbor(direction)
	return HexMetrics.get_edge_type(elevation, neighbor.elevation if neighbor != null else HexMetrics.Edge_types.Flat)
