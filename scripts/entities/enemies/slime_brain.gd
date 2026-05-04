class_name SlimeBrain
extends EnemyBrain

func _ready() -> void:
	super()
	await actor.ready
	actor.initialize_stats(actor.stat_manager.base_stats)
	actor.skill_handler.setup(actor, &"Slime", actor.stat_manager)

func _physics_process(delta: float) -> void:
	super(delta)
	if not is_instance_valid(player): return
	
	var dist = actor.global_position.distance_to(player.global_position)
	var dir = (player.global_position - actor.global_position).normalized()
	actor.set_facing(player.global_position)
	
	# The slime just chases relentlessly. 
	actor.move(dir, delta)
	
	# If it touches the player, we calculate damage directly for now to avoid writing 
	# the entire MeleeCommand architecture until Phase 14.
	if dist < 30.0 and actor.can_attack:
		var dummy_cmd = SkillCommand.new()
		dummy_cmd.base_damage = 10.0
		dummy_cmd.knockback_force = 500.0 # High knockback so player bounces away
		var result = CombatResolver.resolve(actor.stat_manager.base_stats, dummy_cmd, null, dir)
		player.take_damage(result)
		
		# Put the slime in recovery so it doesn't hit 60 times a second
		actor.state_chart.send_event("skill_requested")
