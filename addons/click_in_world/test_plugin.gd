tool
extends EditorPlugin

var inited = false

func _ready():
	print("hehe")
	print("hehe")

func forward_spatial_gui_input(camera, event):
	print(inited)
	if not inited:
		init()
		inited = true
	return false

func save_external_data():
	print("save")
	deinit()

