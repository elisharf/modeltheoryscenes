class_name Utility

# Scripts for handling properties
const ft_to_px = 12
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

func _Standard(args,standards):
	for arg in args:
		arg = arg.split(',')
		var property = arg[0]
		var standard = arg[1]
		standards[property] = standard

func _Happy(args,entities):
	for arg in args:
		if arg in entities:
			var e = entities[arg][0]
			
			var happyface = Sprite2D.new()
			happyface.texture = load("res://Scales/happy.png")
			happyface.scale.x = (e.base_size.x/happyface.texture.get_width())*0.25
			happyface.scale.y = happyface.scale.x
			var value = e.add_scale(happyface, 60, 100)
			e.properties.append("Happiness: " + str(snapped(value,1)) + "/100")
			

func _Tall(args,entities,standards):
	var standard = standards["Tall"]
	standard = int(standard.rstrip("ft"))*ft_to_px
	for arg in args:
		if arg in entities:
			var e = entities[arg][0]
			var rnd = RandomNumberGenerator.new()
			
			var height = e.base_size.y
			var to_display = snapped(height / ft_to_px, 0.01)
			if standard > height:
				e.scale.y = e.scale.y*((standard+rnd.randf_range(1,10))/height)
				to_display = snapped((height*e.scale.y)/ft_to_px, 0.01)
			e.properties.append("Height: "+str(to_display)+"ft (Tall)")

func get_pos(entities,pos):
	if pos in pos_const.keys():
		return pos_const[pos]
	elif pos in entities.keys():
		return entities[pos][0].position
	else:
		return Vector2(scene_width/2,scene_width/2)

func move_entity_to_circle_edge(center: Vector2, radius: float, angle_degrees: float) -> Vector2:
	# Convert degrees to radians
	var angle_radians = deg_to_rad(angle_degrees)

	# Calculate new position on the circle's edge
	var x_new = center.x + radius * cos(angle_radians)
	var y_new = center.y + radius * sin(angle_radians)

	# Return the new position as a Vector2
	return Vector2(x_new, y_new)

func _At(args,entities):
	for arg in args:
		arg = arg.split(',')
		var nm = arg[0]
		var pos = arg[1]
		
		var e = Area2D.new()
		var script = load("res://sprite.gd")
		e.set_script(script)
		e.nm = nm
		e.properties.append(nm)
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

		e.properties.append("At: "+str(snapped(e.position,Vector2(1,1)))+"\n(" + pos + ")")
		entities[nm] = [e, e.base_size*sc]

func handle_property(parsed_property,entities,standards):
	var pred = parsed_property["pred"]
	var args = parsed_property["args"]
	if pred == "At":
		_At(args,entities)
	elif pred == "Tall":
		_Tall(args,entities,standards)
	elif pred == "Happy":
		_Happy(args,entities)
	elif pred == "Standard":
		_Standard(args,standards)


func parse_property(property):
	var parsed_property = {}
	var rex = RegEx.new()
	rex.compile("(?<pred>.+)[ ]*\\=[ ]*\\{(?<args>.+)\\}")
	var result = rex.search(property)
	parsed_property["pred"] = result.get_string("pred").rstrip(" ")

	var arg_str = result.get_string("args")
	if arg_str.contains('<'):
		var argrex = RegEx.new()
		argrex.compile("\\<(?<arg>.+?)\\>")
		parsed_property["args"] = []
		for arg in argrex.search_all(arg_str):
			parsed_property["args"].append(arg.get_string("arg"))
	else:
		var args = arg_str.split(',')
		parsed_property["args"] = []
		for arg in args:
			parsed_property["args"].append(arg.rstrip(" ").lstrip(" "))
	return parsed_property

func sort_and_parse(properties):
	var standards = []
	var ats = []
	var rest = []
	for p in properties:
		if p.is_empty():
			continue
		var parsed = parse_property(p)
		if parsed["pred"] == "Standard":
			standards.append(parsed)
		elif parsed["pred"] == "At":
			ats.append(parsed)
		else:
			rest.append(parsed)
	return standards + ats + rest
		

func handle_properties(properties,entities,standards):
	var sorted_and_parsed = sort_and_parse(properties)
	for property in sorted_and_parsed:
		if not property.is_empty():
			handle_property(property,entities,standards)
