extends SurfaceTool
class_name HexSurfaceTool

var blended : bool = false
var elevation : bool = false
var elevation_step : float = 0
var terranced_edges : bool = false


func _ready():
	pass


func add_hex(hex : HexCell):
	if blended:
		add_blended_hex(hex)
	else:
		add_flat_hex(hex)


func add_flat_hex(hex : HexCell, factor = 1):
	var colors = [hex.color, hex.color, hex.color]
	var pos = hex.world_pos
	if elevation:
		pos += Vector3(0, elevation_step * hex.elevation, 0)
	for x in HexMetrics.corners.size() - 1:
		add_triangle([pos + HexMetrics.corners[x] * factor, pos + HexMetrics.corners[x + 1] * factor, pos], colors)


func add_blended_hex(hex : HexCell):
	add_flat_hex(hex, HexMetrics.solid_factor)
	var neighbor_colors = hex.get_neighbor_colors()
	for dir in HexMetrics.Directions.SW:
		if neighbor_colors.has(dir):
			add_hex_bridge(hex, dir, neighbor_colors)


func add_hex_bridge(hex : HexCell, direction, neighbor_colors : Dictionary):
	if terranced_edges:
		add_terrace_bridge(hex, direction, neighbor_colors)
	else:
		add_flat_bridge(hex, direction, neighbor_colors)
	
	var next_direction = HexMetrics.direction_next(direction)
	if direction <= HexMetrics.Directions.E && neighbor_colors.has(next_direction):
		if terranced_edges && (hex.get_edge_type(direction) == HexMetrics.Edge_types.Slope || hex.get_edge_type(next_direction) == HexMetrics.Edge_types.Slope 
		|| hex.get_neighbor(direction).get_edge_type(hex.get_neighbor(next_direction)) == HexMetrics.Edge_types.Slope):
			add_terraced_corner(hex, direction)
		else:
			add_flat_corner(hex, direction, neighbor_colors)

	
func add_flat_bridge(hex : HexCell, direction, neighbor_colors : Dictionary):
	# Flat bridge quad
	var next = HexMetrics.direction_next(direction)
	var prev = HexMetrics.direction_previous(direction)
	var pos = hex.world_pos
	var quad_v = triangulate_bridge_edges(hex, direction)
	var quad_colors = [
		hex.color,
		hex.color,
		neighbor_colors[direction] if neighbor_colors.has(direction) else hex.color,
		neighbor_colors[direction] if neighbor_colors.has(direction) else hex.color
	]
	add_quad(quad_v, quad_colors)


func add_flat_corner(hex : HexCell, direction, neighbor_colors : Dictionary):
	var tri_v = triangulate_corner_edges(hex, direction)
	var tri_colors = [hex.color, neighbor_colors[direction], neighbor_colors[HexMetrics.direction_next(direction)]]
	add_triangle(tri_v, tri_colors)


func add_terrace_bridge(hex : HexCell, direction, neighbor_colors):
	if hex.get_edge_type(direction) != HexMetrics.Edge_types.Slope:
		add_flat_bridge(hex, direction, neighbor_colors)
		return
	var edges = triangulate_bridge_edges(hex, direction)
	add_terraced_edge(edges, [hex.color, hex.color, neighbor_colors[direction], neighbor_colors[direction]])


func add_terraced_corner(hex : HexCell, direction):
	var neighbour1 = hex.get_neighbor(direction)
	var neighbour2 = hex.get_neighbor(HexMetrics.direction_next(direction))
	if neighbour1 == null || neighbour2 == null:
		return
	var neightbour1edge = hex.get_edge_type(neighbour1)
	var neightbour2edge = hex.get_edge_type(neighbour2)
	var edges = triangulate_corner_edges(hex, direction)
	# TODO Finish Terranced Corners
	var e = [edges[0], edges[0], edges[1], edges[2]]
	var c = [hex.color, hex.color, neighbour1.color, neighbour2.color]
	
	if neightbour1edge == HexMetrics.Edge_types.Flat:
		e = [edges[2], edges[2], edges[0], edges[1]]
		c = [c[3], c[3], c[0], c[2]]
	elif neightbour2edge == HexMetrics.Edge_types.Flat:
		e = [edges[1], edges[1], edges[2], edges[0]]
		c = [c[2], c[2], c[3], c[0]]
	
	# Any neighbour connections are cliffs
	if neightbour1edge == HexMetrics.Edge_types.Cliff || neightbour2edge == HexMetrics.Edge_types.Cliff || neighbour1.get_edge_type(neighbour2) == HexMetrics.Edge_types.Cliff:
		add_cliff_corner(hex, [neighbour1, neighbour2], [e[0], e[2], e[3]], [c[0], c[2], c[3]])
		return
	add_terraced_edge(e, c, 1)


func add_cliff_corner(hex : HexCell, neighbours, edges, colors):
	# Sorts edges and colors so [0] is the lowest vertex
	if edges[1].y < edges[0].y && edges[1].y < edges[2].y:
		edges = [edges[1], edges[2], edges[0]]
		colors = [colors[1], colors[2], colors[0]]
		var new_hex = neighbours[0]
		neighbours = [neighbours[1], hex]
		hex = new_hex
	elif edges[2].y < edges[0].y && edges[2].y < edges[1].y:
		edges = [edges[2], edges[0], edges[1]]
		colors = [colors[2], colors[0], colors[1]]
		var new_hex = neighbours[1]
		neighbours = [hex, neighbours[0]]
		hex = new_hex
	
	var neighbour_edge = neighbours[0].get_edge_type(neighbours[1])
	var cliff_neighbour = int(neighbours[0].elevation < neighbours[1].elevation)
	var b = 1.0 / (neighbours[cliff_neighbour].elevation - hex.elevation)
	var cliff_vert_index = 1 + cliff_neighbour
	var cliff_vert = edges[cliff_vert_index]
	var cliff_color = colors[cliff_vert_index]
	
	var boundary_vert = lerp(edges[0], cliff_vert, b)
	var boundary_color = lerp(colors[0], cliff_color, b)
	
	
	# Top Half
	if neighbour_edge == HexMetrics.Edge_types.Cliff:
		if cliff_neighbour == 0:
			add_triangle([boundary_vert, cliff_vert, edges[2]], [boundary_color, cliff_color, colors[2]])
		else:
			add_triangle([edges[1], cliff_vert, boundary_vert], [colors[1], cliff_color, boundary_color])
	# Double Cliffs
	elif hex.get_edge_type(neighbours[0]) == HexMetrics.Edge_types.Cliff && hex.get_edge_type(neighbours[1]) == HexMetrics.Edge_types.Cliff:
		if neighbour_edge == HexMetrics.Edge_types.Slope:
			# TODO Fix double cliffs
			var double_boundary = lerp(edges[0], cliff_vert, b * 2)
			var double_boundary_color = lerp(colors[0], cliff_color, b * 2)
			if cliff_neighbour == 0:
				add_triangle([edges[0], double_boundary, edges[2]], [colors[0], double_boundary_color, colors[2]])
				add_terranced_triangle([cliff_vert, edges[2], double_boundary], [cliff_color, colors[2], double_boundary_color])
			else:
				add_triangle([edges[0], edges[1], double_boundary], [colors[0], colors[1], double_boundary_color])
				add_terranced_triangle([edges[1], cliff_vert, double_boundary], [colors[1], cliff_color, double_boundary_color])
			return
	else:
		if cliff_neighbour == 0:
			add_terranced_triangle([cliff_vert, edges[2], boundary_vert], [cliff_color, colors[2], boundary_color])
		else:
			add_terranced_triangle([edges[1], cliff_vert, boundary_vert], [colors[1], cliff_color, boundary_color])
	
	# Lower half
	if cliff_neighbour == 0:
		add_terranced_triangle([edges[2], edges[0], boundary_vert], [colors[2], colors[0], boundary_color], 1)
	else:
		add_terranced_triangle([edges[0], edges[1], boundary_vert], [colors[0], colors[1], boundary_color], 1)


func add_terraced_edge(edges, colors, index := 0):
	var v = [null, null, null, null]
	var c = [null, null, null, null]
	for x in range(index, HexMetrics.terrance_steps + 1):
		v[0] = v[2] if v[2] != null else edges[0]
		v[1] = v[3] if v[3] != null else edges[1]
		v[2] = HexMetrics.terrance_lerp(edges[0], edges[2], x)
		v[3] = HexMetrics.terrance_lerp(edges[1], edges[3], x)
		
		c[0] = c[2] if c[2] != null else colors[0]
		c[1] = c[3] if c[3] != null else colors[1]
		c[2] = HexMetrics.terrance_lerp_color(colors[0], colors[2], x)
		c[3] = HexMetrics.terrance_lerp_color(colors[1], colors[3], x)
		add_quad(v, c)


func add_terranced_triangle(edges, colors, index := 0):
	var v = [null, null, edges[2]]
	var c = [null, null, colors[2]]
	for x in range(index, HexMetrics.terrance_steps + 1):
		v[0] = v[1] if v[1] != null else edges[0]
		v[1] = HexMetrics.terrance_lerp(edges[0], edges[1], x)
		
		c[0] = c[1] if c[1] != null else colors[0]
		c[1] = HexMetrics.terrance_lerp_color(colors[0], colors[1], x)
		add_triangle(v, c)


func triangulate_bridge_edges(hex : HexCell, direction):
	var pos = hex.world_pos
	var elevation_hex = Vector3(0, elevation_step * hex.elevation, 0) if elevation else Vector3.ZERO
	var elevation_dir = Vector3(0, elevation_step * hex.neighbors[direction].elevation, 0) if elevation else Vector3.ZERO
	var quad_v = [
		pos + HexMetrics.get_first_solid_corner(direction) + elevation_hex,
		pos + HexMetrics.get_second_solid_corner(direction) + elevation_hex,
		pos + HexMetrics.get_first_solid_corner(direction) + HexMetrics.get_bridge(direction) + elevation_dir,
		pos + HexMetrics.get_second_solid_corner(direction) + HexMetrics.get_bridge(direction) + elevation_dir]
	return quad_v


func triangulate_corner_edges(hex : HexCell, direction):
	var pos = hex.world_pos
	var elevation_hex = Vector3(0, elevation_step * hex.elevation, 0) if elevation else Vector3.ZERO
	var elevation_dir = Vector3(0, elevation_step * hex.get_neighbor(direction).elevation, 0) if elevation else Vector3.ZERO
	var elevation_dir2 = Vector3(0, elevation_step * hex.get_neighbor(HexMetrics.direction_next(direction)).elevation, 0) if elevation else Vector3.ZERO
	var tri_v = [
		pos + HexMetrics.get_second_solid_corner(direction) + elevation_hex,
		pos + HexMetrics.get_second_solid_corner(direction) + HexMetrics.get_bridge(direction) + elevation_dir,
		pos + HexMetrics.get_second_solid_corner(direction) + HexMetrics.get_bridge(HexMetrics.direction_next(direction)) + elevation_dir2]
	return tri_v

func add_quad(corners : Array, colors):
	add_triangle([corners[0], corners[3], corners[1]], [colors[0], colors[3], colors[1]])
	add_triangle([corners[0], corners[2], corners[3]], [colors[0], colors[2], colors[3]])


func add_triangle(corners : Array, colors):
	add_loaded_vertex(corners[0], Vector2(0,0), colors[0])
	add_loaded_vertex(corners[1], Vector2(0,0), colors[1])
	add_loaded_vertex(corners[2], Vector2(0,0), colors[2])


func add_loaded_vertex(pos : Vector3, uv : Vector2, color : Color):
	add_color(color)
	add_uv(uv)
	add_vertex(pos)
