extends EditorProperty

var control = Label.new()

var current_value

func _ready():
	pass


func _init():
	add_child(control)
	add_focusable(control)
	refresh()
	

func update_property():
	current_value = get_edited_object()[get_edited_property()]
	refresh()

func refresh():
	control.text = str(current_value)
