extends Control

@onready var property_handler = Utility.new()
@onready var n_rows = 3
@onready var n_columns = 2
@onready var submit = get_node("Model/VBoxContainer/Submit")  # Path to the Button node
@onready var universe = get_node("Model/VBoxContainer/HBoxContainer/Universe")  # Path to the LineEdit node
@onready var properties = get_node("Model/VBoxContainer/HBoxContainer2/Properties")  # Path to the LineEdit node
@onready var cg = get_node("Model/VBoxContainer/VBoxContainer/CG")  # Path to the LineEdit node
@onready var worlds = Control.new()  # Path to the node where you render the scene
@onready var standards = {}

# CONSTANTS
const screen_width = 1152
const scene_width = 650

func _ready():
	submit.connect("pressed", _on_click)


func _on_click():
	process_input()


func background_init(entities,canvas):

	var background = TextureRect.new()
	background.texture = load("res://Background/background.png")
	background.set_anchors_preset(PRESET_FULL_RECT)
	var border = TextureRect.new()
	border.texture = load("res://Background/border.png")
	border.anchor_left = -0.03
	border.anchor_top = -0.1
	canvas.add_child(background)
	canvas.add_child(border)

	property_handler.handle_properties(cg.text.split('\n'),entities,standards)
	for entity in entities.keys():
		canvas.add_child(entities[entity][0])
	return canvas

func check_universe() -> bool:
	return !universe.text.is_empty()


func universe_init(entities,canvas):
	property_handler.handle_properties(properties.text.split('\n'),entities,standards)
	var De = universe.text.split(',')
	for e in De:
		if e in entities.keys():
			canvas.add_child(entities[e][0])

func setup_world(index,world):
	var x = index % n_columns
	var y = int(index) / int(n_columns)
	var width = scene_width / n_columns
	var length = scene_width / ((n_rows*n_columns) / n_columns)
	world.position = Vector2(x*width,y*length)
	world.size = Vector2(scene_width,scene_width)
	world.scale = Vector2(float(width)/float(scene_width),float(length)/float(scene_width))

func reset_worlds():
	worlds.free()
	worlds = Control.new()
	worlds.size = Vector2(scene_width,scene_width)
	worlds.position = Vector2(screen_width-scene_width, 0)
	get_viewport().set_physics_object_picking_sort(true)
	if get_child_count() > 1:
		remove_child(worlds)
	add_child(worlds)


func process_input():
	# Use the input value to change the rendered scene
	# For example, create a new object or change properties
	reset_worlds()
	
	var n_worlds = n_rows*n_columns
	for i in range(n_worlds):
		var world = SubViewportContainer.new()
		var script = load("res://world.gd")
		setup_world(i, world)
		world.set_script(script)
		worlds.add_child(world)

		var entities = {}
		var canvas = CanvasLayer.new()
		background_init(entities,canvas)
		if check_universe():
			universe_init(entities,canvas)
		world.viewport.get_child(0).add_child(canvas)
