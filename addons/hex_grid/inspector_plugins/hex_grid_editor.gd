extends EditorInspectorPlugin




func _ready():
	pass


func can_handle(object):
	return object is HexGrid


func parse_begin(object):
	var clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.connect("button_down", object, "clear")
	add_custom_control(clear_button)
	var render_button = Button.new()
	render_button.text = "Render"
	render_button.connect("button_down", object, "render")
	add_custom_control(render_button)
