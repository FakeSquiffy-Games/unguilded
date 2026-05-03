@tool
extends EditorScript

func _run() -> void:
	var enemy_scenes = [
		"res://scenes/enemies/enemy_base.tscn",
		"res://scenes/enemies/enemy_complex.tscn",
		"res://scenes/enemies/enemy_simple.tscn"
	]
	
	for path in enemy_scenes:
		var scene = load(path)
		if scene:
			var instance = scene.instantiate()
			# Set Layer to 2 (bit 1) and Mask to 5 (Player + Obstacles)
			instance.collision_layer = 2
			instance.collision_mask = 5
			
			var packed = PackedScene.new()
			packed.pack(instance)
			ResourceSaver.save(packed, path)
			print("Updated Physics Layers for: ", path)
