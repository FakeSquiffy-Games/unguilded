@tool
extends EditorScript

func _run() -> void:
	# 1. Setup Collision Layers
	ProjectSettings.set_setting("layer_names/2d_physics/layer_1", "Player")
	ProjectSettings.set_setting("layer_names/2d_physics/layer_2", "Enemies")
	ProjectSettings.set_setting("layer_names/2d_physics/layer_3", "Obstacles")
	ProjectSettings.set_setting("layer_names/2d_physics/layer_4", "PlayerProjectiles")
	ProjectSettings.set_setting("layer_names/2d_physics/layer_5", "EnemyProjectiles")
	ProjectSettings.save()
	
	# 2. Generate the Arrow Prefab
	var arrow = CharacterBody2D.new()
	arrow.name = "Arrow"
	arrow.collision_layer = 8 # Layer 4 (PlayerProjectiles)
	arrow.collision_mask = 6  # Layer 2 (Enemies) + Layer 3 (Obstacles)
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var tex = load("res://icon.svg")
	sprite.texture = tex
	sprite.scale = Vector2(0.3, 0.1) # Make it look like a thin arrow
	sprite.modulate = Color.AQUA
	arrow.add_child(sprite)
	sprite.owner = arrow
	
	var shape = CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect = RectangleShape2D.new()
	rect.size = Vector2(35, 10)
	shape.shape = rect
	arrow.add_child(shape)
	shape.owner = arrow
	
	var notifier = VisibleOnScreenNotifier2D.new()
	notifier.name = "VisibleOnScreenNotifier2D"
	arrow.add_child(notifier)
	notifier.owner = arrow
	
	var packed = PackedScene.new()
	packed.pack(arrow)
	ResourceSaver.save(packed, "res://scenes/projectiles/arrow.tscn")
	
	print("Phase 8.5: Physics Layers and Arrow Prefab Generated!")
