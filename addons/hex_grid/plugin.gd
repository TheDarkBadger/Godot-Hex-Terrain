tool
extends EditorPlugin

var hex_grid_inspector

func _enter_tree():
	# Initialization of the plugin goes here
	add_custom_type("HexGrid", "HexGrid", preload("hex_grid.gd"), preload("icons/hex_icon.png"))
	hex_grid_inspector = preload("inspector_plugins/hex_grid_editor.gd").new()
	#add_inspector_plugin(hex_grid_inspector)

func _exit_tree():
	# Clean-up of the plugin goes here
	remove_custom_type("HexGrid")
	#remove_inspector_plugin(hex_grid_inspector)
