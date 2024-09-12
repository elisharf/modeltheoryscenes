extends Node2D

var sprite_dict = {}

func _ready():
	var layer = CanvasLayer.new()
	add_child(layer)
	load_background(layer)
	load_json_and_generate_scene(layer)


func load_background(layer):
	var bckgrnd = TextureRect.new()
	bckgrnd.texture = load("res://Background/sunsetvillage.png")
	bckgrnd.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bckgrnd)

func load_json_and_generate_scene(layer):
	var file = FileAccess.open("res://scene_data.json", FileAccess.READ)
	var json_data = JSON.new()
	json_data.parse(file.get_as_text())
	file.close()

	if typeof(json_data.get_data()) == TYPE_DICTIONARY:
		generate_scene_from_json(json_data.get_data(), layer)

func generate_scene_from_json(json_data,layer):
	var universe = json_data["universe"]
	var positions = json_data["positions"]

	for item in universe:
		var sprite = Sprite2D.new()
		sprite.texture = load("res://Sprites/%s.png" % item)
		sprite.position = Vector2(positions[item]["x"], positions[item]["y"])
		sprite.scale = Vector2(0.2,0.2)
		layer.add_child(sprite)
		sprite_dict[item] = sprite

	# You can add further logic here for handling attributes like 'tall', 'happy', etc.
