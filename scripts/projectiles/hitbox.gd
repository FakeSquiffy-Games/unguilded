class_name Hitbox
extends Area2D

var creator: Node2D
var skill_data: SkillCommand
var attacker_stats: StatBlock

var hit_targets: Array[Node] =[]
var lifetime: float = 0.0
var tick_rate: float = 0.0
var tick_timer: float = 0.0

var is_continuous: bool = false
var deadman_timer: float = 0.1 # Self-destructs if not fed by execute_process

func init_hitbox(p_creator: Node2D, p_skill: SkillCommand, p_stats: StatBlock, p_layer: int, p_mask: int, p_lifetime: float, p_tick_rate: float) -> void:
	creator = p_creator
	skill_data = p_skill
	attacker_stats = p_stats
	
	collision_layer = p_layer
	collision_mask = p_mask
	
	lifetime = p_lifetime
	tick_rate = p_tick_rate
	tick_timer = tick_rate
	hit_targets.clear()
	
	is_continuous = (lifetime <= 0.0)
	deadman_timer = 0.1
	
	# Safe signal connection
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# 1. Deadman's Switch for Hold Skills (e.g. Flamethrower)
	if is_continuous:
		deadman_timer -= delta
		if deadman_timer <= 0.0:
			_despawn()
			return
			
	# 2. Standard Lifetime for Tap Skills (e.g. Quick Slash)
	elif lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			_despawn()
			return

	# 3. Tick Damage Logic
	if tick_rate > 0.0:
		tick_timer -= delta
		if tick_timer <= 0.0:
			hit_targets.clear() # Forget old targets so they can be hit again
			tick_timer = tick_rate
			# Instantly re-check overlapping bodies
			for body in get_overlapping_bodies():
				_try_hit(body)

func feed_deadman_switch() -> void:
	deadman_timer = 0.1

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _try_hit(body: Node) -> void:
	if body in hit_targets: return
	
	if body.has_method("take_damage"):
		# Calculate pushback direction outward from the creator
		var origin = creator.global_position if is_instance_valid(creator) else global_position
		var dir = (body.global_position - origin).normalized()
		
		var result = CombatResolver.resolve(attacker_stats, skill_data, null, dir)
		body.take_damage(result)
		hit_targets.append(body)

func _despawn() -> void:
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	PoolManager.release(self)
