extends Control


@onready var n_rows = 3
@onready var n_columns = 2
@onready var submit = get_node("Model/VBoxContainer/Submit")  # Path to the Button node
@onready var universe = get_node("Model/VBoxContainer/HBoxContainer/Universe")  # Path to the LineEdit node
@onready var properties = get_node("Model/VBoxContainer/HBoxContainer2/Properties")  # Path to the LineEdit node
@onready var cg = get_node("Model/VBoxContainer/VBoxContainer/CG")  # Path to the LineEdit node
@onready var worlds = Control.new()  # Path to the node where you render the scene

# CONSTANTS
const screen_width = 1152
const scene_width = 650
const pos_const = {
	"topleft": Vector2(scene_width*0.25,scene_width*0.25),
	"bottomleft": Vector2(scene_width*0.25,scene_width*0.75),
	"topright": Vector2(scene_width*0.75,scene_width*0.25),
	"bottomright": Vector2(scene_width*0.75,scene_width*0.75),
	"center": Vector2(scene_width*0.5,scene_width*0.5)
}
const locations = ["house1","house2"]
const scale_dict = {
	"house1": Vector2(1.5,1.5),
	"house2": Vector2(0.5,0.5),
}

func _ready():
	submit.connect("pressed", _on_click)


func _on_click():
	process_input()


func parse_property(property):
	var parsed_property = {}
	var rex = RegEx.new()
	rex.compile("(?<pred>.+) \\= \\{(?<args>.+)\\}")
	var result = rex.search(property)
	parsed_property["pred"] = result.get_string("pred")

	var arg_str = result.get_string("args")
	if arg_str.contains('<'):
		var argrex = RegEx.new()
		argrex.compile("\\<(?<arg>.+?)\\>")
		parsed_property["args"] = []
		for arg in argrex.search_all(arg_str):
			parsed_property["args"].append(arg.get_string("arg"))
	else:
		parsed_property["args"] = arg_str.split(',')
	return parsed_property

func get_pos(entities,pos):
	if pos in pos_const.keys():
		return pos_const[pos]
	elif pos in entities.keys():
		return entities[pos][0].position
	else:
		return Vector2(scene_width/2,scene_width/2)
	

func _Happy(entities, args):
	for arg in args:
		if arg in entities:
			var e = entities[arg][0]
			e.properties.append("Happy")
			
			var happyface = Sprite2D.new()
			happyface.texture = load("res://Scales/happy.png")
			happyface.scale.x = (e.base_size.x/happyface.texture.get_width())*0.25
			happyface.scale.y = happyface.scale.x
			e.add_scale(happyface, 60, 100)

func _Tall(entities, args):
	for arg in args:
		if arg in entities:
			entities[arg][0].scale.y += 0.2
			entities[arg][0].properties.append("Tall")

func move_entity_to_circle_edge(center: Vector2, radius: float, angle_degrees: float) -> Vector2:
	# Convert degrees to radians
	var angle_radians = deg_to_rad(angle_degrees)

	# Calculate new position on the circle's edge
	var x_new = center.x + radius * cos(angle_radians)
	var y_new = center.y + radius * sin(angle_radians)

	# Return the new position as a Vector2
	return Vector2(x_new, y_new)



func _At(entities,args):
	for arg in args:
		arg = arg.split(',')
		var nm = arg[0]
		var pos = arg[1]
		
		var e = Area2D.new()
		var script = load("res://sprite.gd")
		e.set_script(script)
		e.nm = nm
		e.properties.append("At("+pos+")")
		e.position = get_pos(entities,pos)
		e.sprite.texture = load("res://Sprites/%s.png" % nm)
		e.base_size = e.sprite.texture.get_size()
		if nm not in locations:
			e.sprite.hframes = 3
			e.sprite.vframes = 2
			e.sprite.frame = 1
			e.base_size.x /= 3
			e.base_size.y /= 2

		e.add_child(e.sprite)

		var sc = scale_dict[nm] if nm in scale_dict else Vector2(1,1)
		e.scale = sc
		
		# For variation
		if pos in entities.keys():
			var rng = RandomNumberGenerator.new()
			var deg = rng.randf_range(0,360)
			var rad = (entities[pos][1]/2).length()
			e.position = move_entity_to_circle_edge(e.position,rad,deg)

		entities[nm] = [e, e.base_size*sc]

func handle_property(entities,parsed_property):
	var pred = parsed_property["pred"]
	var args = parsed_property["args"]
	if pred == "At":
		_At(entities,args)
	elif pred == "Tall":
		_Tall(entities,args)
	elif pred == "Happy":
		_Happy(entities,args)

func handle_properties(entities,props):
	for property in props:
		if not property.is_empty():
			handle_property(entities,parse_property(property))

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

	handle_properties(entities,cg.text.split('\n'))
	for entity in entities.keys():
		canvas.add_child(entities[entity][0])
	return canvas

func check_universe() -> bool:
	return !universe.text.is_empty()


func universe_init(entities,canvas):
	handle_properties(entities,properties.text.split('\n'))
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
