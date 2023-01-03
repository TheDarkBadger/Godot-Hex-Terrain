extends MeshInstance
class_name HexGrid

export var width := 10
export var height := 10
export var show_cords : bool = true
export var elevation : bool = true
export var elevation_step : float = 0.2
export var blend_hexes : bool = true
export var terranced_edges : bool = true
export var terrances_per_slope : int = 2
export var irregular : bool = true
var noise_irregular := OpenSimplexNoise.new()
export(Array) var colors
# {cords : Vector2, cell : HexCell}
export var cells := {}

var label_holder := Node.new()

func _ready():
	label_holder.name = "Labels"
	add_child(label_holder)
	
	var pos1 = VectorHex.new(5, 7)
	var pos2 = VectorHex.new(11, 9)
	var world_pos = Vector3(9.526279, 0, 10.5)
	var world_pos2 = Vector3(19.918585, 0, 13.5)
	assert(pos1.to_grid_cords() == Vector2(5, 7))
	assert(pos2.to_grid_cords() == Vector2(11, 9))
	assert(HexMetrics.cell_world_pos(5, 7).is_equal_approx(world_pos))
	assert(HexMetrics.cell_world_pos(11, 9).is_equal_approx(world_pos2))
	
	print(HexMetrics.cell_world_pos(11, 9))
	print(HexMetrics.world_to_cell(world_pos))#5,7
	print(HexMetrics.world_to_cell(world_pos2))#11,9

	#assert(HexMetrics.world_to_cell(world_pos) == Vector2(5, 7))
	#assert(HexMetrics.world_to_cell(world_pos2) == Vector2(11, 9))
	# Check distances
	assert(VectorHex.distance(pos1, pos2) == 4)
	
	# Check directions
	assert(HexMetrics.direction_next(HexMetrics.Directions.NE) == HexMetrics.Directions.E)
	assert(HexMetrics.direction_next(HexMetrics.Directions.NW) == HexMetrics.Directions.NE)
	assert(HexMetrics.direction_previous(HexMetrics.Directions.NE) == HexMetrics.Directions.NW)
	assert(HexMetrics.direction_previous(HexMetrics.Directions.NW) == HexMetrics.Directions.W)
	
	render()


func load_cells():
	for x in width:
		for y in height:
			create_cell(VectorHex.new(x, y))


func clear():
	cells.clear()
	mesh = null
	for child in label_holder.get_children():
		child.queue_free()


func render():
	clear()
	load_cells()
	mesh = create_mesh()


func create_mesh() -> ArrayMesh:
	var st = HexSurfaceTool.new()
	st.blended = blend_hexes
	st.elevation = elevation
	st.elevation_step = elevation_step
	st.terranced_edges = terranced_edges
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in width:
		for y in height:
			var cell : HexCell = cells[VectorHex.grid_to_hex_cords(x, y)]
			st.add_hex(cell)
			if show_cords:
				create_cell_label(cell)
	
	st.generate_normals()
	st.generate_tangents()
	st.index()
	return st.commit()


func create_cell(cords : VectorHex):
	var index = cords.to_vector2()
	if cells.has(index):
		printerr("Unable to create cell at %s, a cell already exists there" % cords.to_string())
		return null
	var cell = HexCell.new(cords, colors[randi() % colors.size()], randi() % 4)
	set_cell_neighbors(cell)
	cells[index] = cell
	return cell


func create_cell_label(cell : HexCell) -> Spatial:
	var label = Label3D.new()
	label.text = cell.cords.to_string()
	label.name = "Label (%s)" % label.text
	label_holder.add_child(label)
	var elevation = Vector3(0, elevation_step * cell.elevation, 0) if elevation else Vector3.ZERO
	label.translation = cell.cords.to_world_pos() + Vector3(0, 0.25, 0) + elevation
	label.rotate(Vector3.LEFT, 90)
	label.no_depth_test = true
	label.pixel_size = 0.0256
	label.billboard = SpatialMaterial.BILLBOARD_ENABLED
	return label


func set_cell_neighbors(cell : HexCell):
	for dir in 6:
		var neighbor_cords = cell.cords.get_neighbor(dir)
		if cells.has(neighbor_cords):
			cell.set_neighbor(dir, cells[neighbor_cords])
