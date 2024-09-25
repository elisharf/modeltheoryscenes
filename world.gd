extends SubViewportContainer

var base_position
var full_size = Vector2(650,650)
var is_fullscreen: bool = false
var viewport: Viewport
const n_windows = 4

func _ready():
	# Create a Viewport and set its initial size
	stretch = true
	z_index = 0
	base_position = position
	viewport = SubViewport.new()
	add_child(viewport)
	size = full_size/(n_windows/2)  # Start with a smaller size

	# Add content to the viewport (e.g., a simple scene or a label)
	var node = Node2D.new()
	viewport.add_child(node)
	# Detect clicks on the ViewportContainer
	connect("gui_input", _on_viewport_click)

func _on_viewport_click(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Toggle between small size and fullscreen
		if not is_fullscreen:
			# Set to fullscreen or expand the viewport
			position = Vector2(0,0)
			size = full_size
			z_index = 1
			is_fullscreen = true
		else:
			# Return to the smaller size
			position = base_position
			size = full_size/(n_windows/2)
			z_index = 0
			is_fullscreen = false
