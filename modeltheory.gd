extends Control

@onready var entity_dict = {}
@onready var submit = get_node("Model/VBoxContainer/Submit")  # Path to the Button node
@onready var universe = get_node("Model/VBoxContainer/HBoxContainer/Universe")  # Path to the LineEdit node
@onready var properties = get_node("Model/VBoxContainer/HBoxContainer2/Properties")  # Path to the LineEdit node
@onready var cg = get_node("Model/VBoxContainer/VBoxContainer/CG")  # Path to the LineEdit node
@onready var scene = get_node("Scene/Node2D")  # Path to the node where you render the scene

# CONSTANTS
const pos_const = {
	"topleft": Vector2(100,100),
	"bottomleft": Vector2(100,500),
	"topright": Vector2(500,100),
	"bottomright": Vector2(500,500)
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
		return entity_dict[pos][0].position + entity_dict[pos][1]/2
	else:
		return Vector2(500,500)

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


func process_input():
	# Use the input value to change the rendered scene
	# For example, create a new object or change properties
	var canvas = background_init()
	scene.add_child(canvas)  # Add the node to the render area
	if check_universe():
		universe_init(canvas)
