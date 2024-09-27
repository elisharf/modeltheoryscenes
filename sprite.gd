extends Area2D

var scales = []
var properties = []
var sprite = Sprite2D.new()
var property_box = Label.new()
var property_box_theme = preload("res://Themes/property_box.tres")
var clicked: bool = false
var base_position
var base_scale
var base_size
var nm
var shape_container = CollisionShape2D.new()
var shape = RectangleShape2D.new()
var block_input = false

const scene_width = 650
const scale_factor = 1.5

func _ready():
	# Create a Viewport and set its initial size
	z_index = 1
	base_position = position
	base_scale = scale
	
	# Add content to the viewport (e.g., a simple scene or a label)
	shape.size = base_size
	shape_container.set_shape(shape)
	add_child(shape_container)

func set_block_input(block):
	block_input = block

func focus_clicks():
	for child in get_parent().get_children():
		if child.is_class("Area2D") and child != self:
			child.set_block_input(true)

func allow_clicks():
	for child in get_parent().get_children():
		if child.is_class("Area2D"):
			child.set_block_input(false)

func add_scale(image, min_value, max_value):
	var bar = ProgressBar.new()
	
	bar.theme = load("res://Themes/progress_bar.tres")
	bar.show_percentage = false
	bar.size.x = base_size.x
	bar.position = Vector2(0,0)
	bar.position.x -= base_size.x/2
	bar.position.y -= base_size.y/2 + 10
	bar.min_value = 0
	bar.max_value = 100
	var rnd = RandomNumberGenerator.new()
	bar.value = rnd.randf_range(min_value,max_value)
	image.position = bar.position
	image.position.x += (bar.value / bar.max_value)*base_size.x

	scales.append(bar)
	add_child(bar)
	add_child(image)	
	return bar.value

func add_property_box():
	property_box.size = shape.size*scale
	property_box.position = position
	property_box.position.y -= property_box.size.y/2
	property_box.position.x += property_box.size.x/2
	property_box.text = "\n".join(properties)
	property_box.theme = property_box_theme
	get_parent().add_child(property_box)

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	viewport.set_input_as_handled()
	if !block_input and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not clicked:
			# Only allow interactions with entity.
			clicked = true
			focus_clicks()
			viewport.get_parent().set_block_input(true)
			
			# Center, zoom in, show properties
			scale = base_scale*scale_factor
			position = Vector2(scene_width*.5,scene_width*.5)
			add_property_box()
		else:
			# Allow clicks on any entity
			clicked = false
			allow_clicks()
			viewport.get_parent().set_block_input(false)

			# Return to the smaller size
			scale = base_scale
			position = base_position
			get_parent().remove_child(property_box)
