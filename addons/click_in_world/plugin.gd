tool
extends EditorPlugin

const horizontal_plane_scene = preload("res://addons/click_in_world/PlaneView.tscn")
const vertical_plane_scene = preload("res://addons/click_in_world/PlaneView.tscn")

var horizontal_plane = null
var vertical_plane = null

var pressed = false
var dragging = false
var last_mouse_pos = Vector2.ZERO
var cursor = Vector3.ZERO
var flat_pos = Vector2.ZERO
var camera
var current_cube
var drag_height_start

func root():
	return get_tree().get_edited_scene_root()

var inited = false

func init_scene(scene):
	if scene == null:
		deinit()
	else:
		init()

func init():
	deinit()	
	print("init! ")
	
	print("lol")
	
	if root():
		horizontal_plane = horizontal_plane_scene.instance()
		vertical_plane = vertical_plane_scene.instance()
		
		horizontal_plane.add_to_group("click_in_world")
		vertical_plane.add_to_group("click_in_world")
		
		
		vertical_plane.rotation.x = PI / 2
		horizontal_plane.collision_layer = 0b1000
		vertical_plane.collision_layer = 0b0100
		
		root().add_child(horizontal_plane)
		root().add_child(vertical_plane)
		inited = true
		print("inited!")

func deinit():
	get_tree().call_group("click_in_world", "queue_free")
	
	inited = false
	print("deinited")

var button = preload("res://addons/click_in_world/button.tscn").instance()

var enabled = false

func enable(on):
	enabled = on
	if enabled:
		init()
	else:
		deinit()

func _enter_tree():
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
	button.get_child(0).connect("toggled", self, "enable")
	print("enter tree")
	connect("scene_changed", self, "init_scene")

func _exit_tree():
	print("exit tree")
	deinit()
	button.get_parent().remove_child(button)

func _input(event):
	if event is InputEventKey and event.scancode == KEY_ALT:
		if event.pressed:
			drag_height_start = cursor
		else:
			drag_height_start = null

func mouse_on_horizontal():
	var root: Spatial = get_tree().get_edited_scene_root()
	var state = root.get_world().direct_space_state
	
	var from = camera.project_ray_origin(last_mouse_pos)
	var normal = camera.project_ray_normal(last_mouse_pos)
	
	var res = state.intersect_ray(from, from + normal * 1000, [], 0b1000)
	
	if res:
		return res.position
	else:
		print("no hit horizontal")

func mouse_on_vertical():
	var root: Spatial = get_tree().get_edited_scene_root()
	var state = root.get_world().direct_space_state
	
	var from = camera.project_ray_origin(last_mouse_pos)
	var normal = camera.project_ray_normal(last_mouse_pos)
	
	var res = state.intersect_ray(from, from + normal * 1000, [], 0b0100)
	
	if res:
		return res.position
	else:
		print("no hit vertical")

func on_down():
	pressed = true
	
	var pos = cursor
	if pos:
		var root = get_tree().get_edited_scene_root()
		var to_spawn: Spatial = load("res://addons/click_in_world/Cube.tscn").instance()
		current_cube = to_spawn
		to_spawn.transform.origin = pos
		to_spawn.scale = Vector3(1, 1, 1)
		update_current_cube()
		root.add_child(to_spawn)
		to_spawn.owner = root
		dragging = pos

var current_height = 1
var p2 = null

func update_current_cube():
	#if drag_height_start:
	#	current_height = cursor.y - drag_height_start.y
	#else:
	p2 = cursor
		
	if p2:
		var p = dragging
		print("p: ", p)
		var start = Vector3(floor(min(p.x, p2.x)), floor(min(p.y, p2.y)), floor(min(p.z, p2.z)))
		var stop = Vector3(floor(max(p.x, p2.x)), floor(max(p.y, p2.y)), floor(max(p.z, p2.z)))
		if start.x == stop.x:
			stop.x = start.x + 1
		if start.y == stop.y:
			stop.y = start.y + 1
		if start.z == stop.z:
			stop.z = start.z + 1
		var center = lerp(start, stop, 0.5)
		var width = stop.x - start.x
		var height = stop.y - start.y
		var depth = stop.z - start.z
		print(height)
		
		current_cube.transform.origin = center
		current_cube.scale = Vector3(width, height, depth)

func on_drag():
	if dragging:
		update_current_cube()

func on_release():
	pressed = false
	if dragging:
		update_current_cube()
		p2 = null
		current_cube = null
		current_height = 1
		dragging = null

func v3floor(v):
	return Vector3(floor(v.x), floor(v.y), floor(v.z))

func forward_spatial_gui_input(camera, event):
	if not enabled:
		return
	if not root():
		return
	if not inited:
		init()

	self.camera = camera
	
	if event is InputEventMouseMotion:
		last_mouse_pos = event.position
		if drag_height_start:
			var flat_pos = v3floor(mouse_on_vertical())
			cursor.y = flat_pos.y
			#cursor.x = flat_pos.x
		else:
			var flat_pos = v3floor(mouse_on_horizontal())
			cursor.x = flat_pos.x
			cursor.z = flat_pos.z
		print(cursor)

	vertical_plane.transform.origin = cursor
	horizontal_plane.transform.origin = cursor
	
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			if not pressed:
				last_mouse_pos = event.position
				on_down()
				return true
		else:
			if pressed:
				last_mouse_pos = event.position
				on_release()
				return true
	
	if pressed:
			on_drag()
		#return true
		
	return false

func save_external_data():
	deinit()

func handles(object):
	return true
