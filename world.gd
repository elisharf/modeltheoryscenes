extends SubViewportContainer

var block_input = false
var base_scale
var base_position
var is_fullscreen: bool = false
var viewport: Viewport

const scene_width = 650

func _ready():
	# Create a Viewport and set its initial size
	
	set_mouse_filter(MOUSE_FILTER_STOP)
	stretch = true
	z_index = 0
	base_position = position
	base_scale = scale
	viewport = SubViewport.new()

	add_child(viewport)

	# Add content to the viewport (e.g., a simple scene or a label)
	var node = Node2D.new()
	viewport.add_child(node)
	# Detect clicks on the ViewportContainer
	connect("gui_input", _on_viewport_click)

func set_block_input(block):
	block_input = block

func focus_clicks():
	for child in get_parent().get_children():
		if child.is_class("SubViewportContainer") and child != self:
			child.set_mouse_filter(MOUSE_FILTER_IGNORE)


func allow_clicks():
	for child in get_parent().get_children():
		if child.is_class("SubViewportContainer"):
			child.set_mouse_filter(MOUSE_FILTER_STOP)


func _on_viewport_click(event):
	if viewport.is_input_handled():
		return
	if !block_input and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Toggle between small size and fullscreen
		if not is_fullscreen:
			# Set to fullscreen or expand the viewport
			scale = Vector2(1,1)
			position = Vector2(0,0)
			z_index = 1
			is_fullscreen = true
			
			focus_clicks()
			event.canceled = true
			viewport.set_physics_object_picking(true)
			viewport.set_physics_object_picking_sort(true)
			viewport.set_physics_object_picking_first_only(true)
		else:
			# Return to the smaller size
			scale = base_scale
			position = base_position
			z_index = 0
			is_fullscreen = false

			allow_clicks()
			event.canceled = true
			viewport.set_physics_object_picking(false)
			viewport.set_physics_object_picking_sort(false)
			viewport.set_physics_object_picking_first_only(false)
