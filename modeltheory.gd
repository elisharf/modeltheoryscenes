extends Control

@onready var n_windows = 6
@onready var n_columns = 2
@onready var worlds = []
@onready var entity_dict = {}
@onready var submit = get_node("Model/VBoxContainer/Submit")  # Path to the Button node
@onready var universe = get_node("Model/VBoxContainer/HBoxContainer/Universe")  # Path to the LineEdit node
@onready var properties = get_node("Model/VBoxContainer/HBoxContainer2/Properties")  # Path to the LineEdit node
@onready var cg = get_node("Model/VBoxContainer/VBoxContainer/CG")  # Path to the LineEdit node
@onready var scenes = Control.new()  # Path to the node where you render the scene

# CONSTANTS
const pos_const = {
	"topleft": Vector2(100,100),
	"bottomleft": Vector2(100,500),
	"topright": Vector2(500,100),
	"bottomright": Vector2(500,500),
	"center": Vector2(325,325)
}
const scale_dict = {
	"house1": Vector2(1.5,1.5),
	"house2": Vector2(0.5,0.5),
}

const locations = ["house1","house2"]

func _ready():
	self.y_sort_enabled = true
	submit.connect("pressed", _on_click)


func _on_click():
	process_input()
	

func parse_property(property):
	var parsed_property = {}
	var rex = RegEx.new()
	rex.compile("(?<pred>.+) \\= \\{(?<args>.+)\\}")
	var result = rex.search(property)
	parsed_property["pred"] = result.get_string("pred")
	
	var argrex = RegEx.new()
	argrex.compile("\\<(?<arg>.+?)\\>")
	parsed_property["args"] = argrex.search_all(result.get_string("args"))
		
	return parsed_property
	
func get_pos(pos):
	if pos in pos_const.keys():
		return pos_const[pos]
	elif pos in entity_dict.keys():
		return entity_dict[pos][0].position
	else:
		return Vector2(500,500)

#func _handle_Tall(args):
	#for arg in args:
		#if arg in entity

func move_entity_to_circle_edge(center: Vector2, radius: float, angle_degrees: float) -> Vector2:
	# Convert degrees to radians
	var angle_radians = deg_to_rad(angle_degrees)
	
	# Calculate new position on the circle's edge
	var x_new = center.x + radius * cos(angle_radians)
	var y_new = center.y + radius * sin(angle_radians)
	
	# Return the new position as a Vector2
	return Vector2(x_new, y_new)

				
func _handle_At(args):
	for arg in args:
		arg = arg.get_string("arg").split(',')
		var e = Area2D.new()
	
		e.collision_mask = 1
		e.collision_layer = 1
		e.monitoring = true
		e.monitorable = true
		
		var texture = Sprite2D.new()
		var nm = arg[0]
		var pos = arg[1]
		texture.texture = load("res://Sprites/%s.png" % nm)
		if nm not in locations:
			texture.hframes = 3
			texture.vframes = 2
			texture.frame = 1

		e.add_child(texture)

		e.position = get_pos(pos)
		
		# For variation
		if pos in entity_dict.keys():
			var rng = RandomNumberGenerator.new()
			var deg = rng.randf_range(0,360)
			var rad = (entity_dict[pos][1]/2).length()
			e.position = move_entity_to_circle_edge(e.position,rad,deg)

		var sc = scale_dict[nm] if nm in scale_dict else Vector2(1,1)
		
		e.scale = sc

		var collision = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		
		rect.size = texture.texture.get_size()*sc
		collision.shape = rect
		e.add_child(collision)
		entity_dict[nm] = [e, rect.size]

func handle_property(parsed_property):
	var pred = parsed_property["pred"]
	var args = parsed_property["args"]
	if pred == "At":
		_handle_At(args)
	#if pred == "Tall":
		#_handle_Tall(args)

func handle_properties(props):
	for property in props:
		if not property.is_empty():
			handle_property(parse_property(property))
	
func background_init():
	
	var canvas = CanvasLayer.new()
	var background = TextureRect.new()
	background.texture = load("res://Background/background.png")
	background.set_anchors_preset(PRESET_FULL_RECT)
	canvas.add_child(background)
	
	handle_properties(cg.text.split('\n'))
	for entity in entity_dict.keys():
		canvas.add_child(entity_dict[entity][0])
	return canvas
	
func check_universe() -> bool:
	return !universe.text.is_empty()
	

func universe_init(canvas):
	handle_properties(properties.text.split('\n'))
	var entities = universe.text.split(',')
	for e in entities:
		if e in entity_dict.keys():
			canvas.add_child(entity_dict[e][0])

func position_world(index):
	var x = index % n_columns
	var y = int(index) / int(n_columns)
	var width = 650 / n_columns
	var length = 650 / (n_windows / n_columns)
	return Vector2(x*width,y*length)

func process_input():
	# Use the input value to change the rendered scene
	# For example, create a new object or change properties
	entity_dict = {}
	worlds = []
	scenes.size = Vector2(650,650)
	scenes.position = Vector2(500,0)
	for child in scenes.get_children():
		child.queue_free()
	
	add_child(scenes)
	for i in range(n_windows):
		var world = SubViewportContainer.new()
		var script = load("res://world.gd")
		world.position = position_world(i)
		world.set_script(script)
		scenes.add_child(world)

		var canvas = background_init()
		if check_universe():
			universe_init(canvas)
		world.viewport.get_child(0).add_child(canvas)
		worlds.append(world)
