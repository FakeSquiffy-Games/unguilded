#@ascii_only
extends Node
## Auto-hashing Object Pool

var _pools: Dictionary = {}

func acquire(scene: PackedScene) -> Node:
	var path = scene.resource_path
	if not _pools.has(path):
		_register_pool(scene, 15)
		
	var pool: Dictionary = _pools[path]
	var inactive: Array = pool["inactive"]
	var instance: Node = null
	
	# FIX: Loop until we find a VALID instance or the array is empty
	while inactive.size() > 0:
		var candidate = inactive.pop_back()
		if is_instance_valid(candidate):
			instance = candidate
			break
	
	# If no valid instances were found in the pool, make a new one
	if instance == null:
		instance = scene.instantiate()
		instance.set_meta("pool_scene", scene)
		add_child(instance)
		
	_wake_instance(instance)
	return instance

func clear_pools() -> void:
	for path in _pools:
		var pool = _pools[path]
		for node in pool["inactive"]:
			if is_instance_valid(node):
				node.queue_free()
		pool["inactive"].clear()
	_pools.clear()

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
	if instance is CanvasItem: 
		instance.visible = false
	instance.position = Vector2(-9999, -9999)
	
	# Sleeping nodes should not exist to game logic
	if instance.is_in_group("enemies"):
		instance.remove_from_group("enemies")

func _wake_instance(instance: Node) -> void:
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance is CanvasItem: 
		instance.visible = true
		instance.z_index = 0
