class_name SkeletonArcherBrain
extends EnemyBrain

@export var attack_range: float = 300.0

func _ready() -> void:
	super()
	await actor.ready
	actor.initialize_stats(actor.stat_manager.base_stats)
	actor.skill_handler.setup(actor, &"Skeleton", actor.stat_manager)

func _physics_process(delta: float) -> void:
	super(delta)
	if not is_instance_valid(player): return
	
	var dist = actor.global_position.distance_to(player.global_position)
	var dir = (player.global_position - actor.global_position).normalized()
	actor.set_facing(player.global_position)
	
	if dist > attack_range:
		actor.move(dir, delta)
	else:
		actor.move(Vector2.ZERO, delta) # Stop moving
		# AI presses the "Left Click" button!
		actor.request_skill("left_tap", dir)
