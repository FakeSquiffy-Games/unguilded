#@ascii_only
extends Node
## Auto-hashing Object Pool

var _pools: Dictionary = {}

func acquire(scene: PackedScene) -> Node:
	var path = scene.resource_path
	if not _pools.has(path):
		_register_pool(scene, 15) # Auto-register if it doesn't exist
		
	var pool: Dictionary = _pools[path]
	var inactive: Array = pool["inactive"]
	var instance: Node
	
	if inactive.size() > 0:
		instance = inactive.pop_back()
	else:
		instance = scene.instantiate()
		instance.set_meta("pool_scene", scene) # Stamp it with its creator scene
		add_child(instance)
		
	_wake_instance(instance)
	return instance

func release(instance: Node) -> void:
	if not instance.has_meta("pool_scene"):
		instance.queue_free()
		return
	
	var scene = instance.get_meta("pool_scene") as PackedScene
	if not scene or not _pools.has(scene.resource_path):
		instance.queue_free()
		return
		
	_sleep_instance(instance)
	_pools[scene.resource_path]["inactive"].append(instance)

func _register_pool(scene: PackedScene, initial_count: int) -> void:
	var inactive: Array[Node] =[]
	for i in initial_count:
		var instance = scene.instantiate()
		instance.set_meta("pool_scene", scene)
		add_child(instance)
		_sleep_instance(instance)
		inactive.append(instance)
	_pools[scene.resource_path] = { "scene": scene, "inactive": inactive }

func _sleep_instance(instance: Node) -> void:
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance is CanvasItem: instance.visible = false
	instance.position = Vector2(-9999, -9999)

func _wake_instance(instance: Node) -> void:
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance is CanvasItem: instance.visible = true
