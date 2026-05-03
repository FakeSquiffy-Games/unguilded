@tool
extends EditorScript

func _run() -> void:
	var arena = Node2D.new()
	arena.name = "Arena"
	
	# 1. The Void (Dark background outside the arena)
	var void_bg = ColorRect.new()
	void_bg.name = "VoidBackground"
	void_bg.color = Color(0.05, 0.05, 0.08)
	void_bg.custom_minimum_size = Vector2(10000, 10000)
	void_bg.position = Vector2(-5000, -5000)
	arena.add_child(void_bg)
	void_bg.owner = arena
	
	# 2. The Playable Floor
	var floor_rect = ColorRect.new()
	floor_rect.name = "ArenaFloor"
	floor_rect.color = Color(0.2, 0.2, 0.25)
	floor_rect.custom_minimum_size = Vector2(2000, 2000)
	floor_rect.position = Vector2(-1000, -1000)
	arena.add_child(floor_rect)
	floor_rect.owner = arena
	
	# 3. Collision Walls
	var walls = StaticBody2D.new()
	walls.name = "ArenaWalls"
	arena.add_child(walls)
	walls.owner = arena
	
	# Top, Bottom, Left, Right
	var rects =[
		{"pos": Vector2(0, -1050), "size": Vector2(2200, 100)},
		{"pos": Vector2(0, 1050), "size": Vector2(2200, 100)},
		{"pos": Vector2(-1050, 0), "size": Vector2(100, 2000)},
		{"pos": Vector2(1050, 0), "size": Vector2(100, 2000)}
	]
	
	for i in range(rects.size()):
		var shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = rects[i]["size"]
		shape.shape = rect_shape
		shape.position = rects[i]["pos"]
		shape.name = "WallShape_" + str(i)
		walls.add_child(shape)
		shape.owner = arena

	# 4. Spawn Points
	var spawns = Node2D.new()
	spawns.name = "SpawnPoints"
	arena.add_child(spawns)
	spawns.owner = arena
	
	# Create 8 spawn points around a radius
	var angles =[0, 45, 90, 135, 180, 225, 270, 315]
	for a in angles:
		var marker = Marker2D.new()
		marker.name = "Spawn_" + str(a)
		marker.position = Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 900
		marker.add_to_group("spawn_points")
		spawns.add_child(marker)
		marker.owner = arena

	# 5. Base Camera & Phantom Camera Host
	var cam = Camera2D.new()
	cam.name = "MainCamera"
	arena.add_child(cam)
	cam.owner = arena
	
	var host = PhantomCameraHost.new()
	host.name = "PhantomCameraHost"
	cam.add_child(host)
	host.owner = arena

	# Save Scene
	var packed = PackedScene.new()
	packed.pack(arena)
	ResourceSaver.save(packed, "res://scenes/arena/arena.tscn")
	print("Phase 7 Arena Generated Successfully!")
