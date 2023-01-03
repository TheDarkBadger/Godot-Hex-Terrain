extends Spatial

export var speed : float = 5
export var raycast_dist : float = 30
export var zoom_min : float = 1.0
export var zoom_max : float = 15.0
export var zoom_speed : float = 0.5

onready var camera = $Camera

export var zoom : float = 5.0

func _ready():
	pass


func _physics_process(delta):
	#if Input.is_action_pressed("move_drag"):
	#	move_to_mouse()
	move(delta)

func move(delta):
	var input = Vector3(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0,
	Input.get_action_strength("move_down") - Input.get_action_strength("move_up"))
	translation.y = zoom
	translate(input * speed * delta)


func _input(event):
	if event.is_action_released("zoom_in"):
		zoom -= zoom_speed
	if event.is_action_released("zoom_out"):
		zoom += zoom_speed
	
	if zoom < zoom_min:
		zoom = zoom_min
	if zoom > zoom_max:
		zoom = zoom_max
	


func move_to_mouse():
	var pos = raycast_at_pos()
	print(HexMetrics.world_to_cell(pos) as String)


func raycast_at_pos():
	var space_state = get_world().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * raycast_dist
	return space_state.intersect_ray(from, to)
