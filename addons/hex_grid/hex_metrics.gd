extends Node
class_name HexMetrics

enum Directions {NE, E, SE, SW, W, NW}

const outer_radius : float = 1.0
const inner_radius : float = outer_radius * 0.866025404;
const solid_factor : float = 0.8
const blend_factor : float = 1.0 - solid_factor
enum Edge_types {Flat, Slope, Cliff}

const corners = [
	Vector3(0,0, -outer_radius),
	Vector3(inner_radius, 0, -0.5 * outer_radius),
	Vector3(inner_radius, 0, 0.5 * outer_radius),
	Vector3(0,0, outer_radius),
	Vector3(-inner_radius, 0, 0.5 * outer_radius),
	Vector3(-inner_radius,0, -0.5 * outer_radius),
	Vector3(0,0, -outer_radius)]
const terrances_per_slope : int = 2
const terrance_steps : int = terrances_per_slope * 2 + 1
const horizontal_terrace_step_size = 1.0 / terrance_steps
const vertical_terrace_step_size = 1.0 / (terrances_per_slope + 1)
const cell_perturb_strength := 0.5
#const cell_elevation_perturb_strength := 0.3
const noise_scale = 2

static func cell_world_pos(x : float, z : float) -> Vector3:
	return Vector3((x + z * 0.5 - int(z / 2)) * (inner_radius * 2), 0, z * (outer_radius * 1.5))


static func world_to_cell(pos : Vector3) -> Vector2:
	var z = int(pos.z / (outer_radius * 1.5))
	# FIXME this doesnt work properly
	var x = int((pos.x - z * 0.5 - int(z/2)) * (inner_radius * 2))
	return Vector2(x, z)


static func opposite_direction(direction):
	var diri = int(direction)
	return (diri + 3) if diri < 3 else (diri - 3);


static func get_bridge(direction):
	return (corners[direction] + corners[direction + 1]) * blend_factor


static func get_first_solid_corner(direction) -> Vector3:
	return corners[direction] * solid_factor


static func get_second_solid_corner(direction) -> Vector3:
	return corners[direction + 1] * solid_factor


static func direction_next(direction):
	return Directions.values()[direction + 1] if direction != Directions.NW else Directions.NE


static func direction_previous(direction):
	return Directions.values()[direction - 1] if direction != Directions.NE else Directions.NW


static func terrance_lerp(a : Vector3, b : Vector3, step : int) -> Vector3:
	var h = step * horizontal_terrace_step_size
	a.x += (b.x - a.x) * h;
	a.z += (b.z - a.z) * h;
	var v = ((step + 1) / 2) * vertical_terrace_step_size
	a.y += (b.y - a.y) * v;
	return a;


static func terrance_lerp_color(a : Color, b : Color, step : int) -> Color:
	var h = step * horizontal_terrace_step_size
	return lerp(a, b, h)


static func get_edge_type(elevation1, elevation2):
	if elevation1 == elevation2:
		return Edge_types.Flat
	var delta = abs(elevation1 - elevation2)
	if delta == 1:
		return Edge_types.Slope
	return Edge_types.Cliff


static func sample_noise(source : Image, x : float, z : float) -> Vector3:
	var color = source.get_pixel(abs(x * noise_scale), abs(z * noise_scale))
	return Vector3(color.r, color.g, color.b)
