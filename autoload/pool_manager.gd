#@ascii_only
extends Node
## Object pool registry for projectiles and enemies.

# Dictionary format: { pool_name: { "scene": PackedScene, "inactive": Array[Node] } }
var _pools: Dictionary = {}

func register_pool(pool_name: StringName, scene: PackedScene, initial_count: int = 20) -> void:
	if _pools.has(pool_name): return
	
	var inactive: Array[Node] =[]
	for i in initial_count:
		var instance := scene.instantiate()
		add_child(instance)
		_sleep_instance(instance)
		inactive.append(instance)
		
	_pools[pool_name] = { "scene": scene, "inactive": inactive }

func acquire(pool_name: StringName) -> Node:
	if not _pools.has(pool_name): return null
	
	var pool: Dictionary = _pools[pool_name]
	var inactive: Array = pool["inactive"]
	var instance: Node
	
	if inactive.size() > 0:
		instance = inactive.pop_back()
	else:
		# Pool exhausted, expand dynamically
		instance = pool["scene"].instantiate()
		add_child(instance)
	
	_wake_instance(instance)
	return instance

func release(pool_name: StringName, instance: Node) -> void:
	if not _pools.has(pool_name):
		instance.queue_free()
		return
		
	_sleep_instance(instance)
	_pools[pool_name]["inactive"].append(instance)

func _sleep_instance(instance: Node) -> void:
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance is CanvasItem:
		instance.visible = false
	instance.position = Vector2(-9999, -9999) # Move offscreen just in case

func _wake_instance(instance: Node) -> void:
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance is CanvasItem:
		instance.visible = true
