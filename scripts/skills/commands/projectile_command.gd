class_name ProjectileCommand
extends SkillCommand

@export var projectile_scene: PackedScene
@export var speed: float = 800.0
@export var is_piercing: bool = false
@export var fire_rate: float = 1.0 # Used for HOLD_CONTINUOUS
@export_flags_2d_physics var collision_layer: int = 8 # Default: Layer 4 (PlayerProjectiles)
@export_flags_2d_physics var collision_mask: int = 6  # Default: Layer 2 (Enemies) + Layer 3 (Obstacles)

@export_group("Multishot")
@export var projectile_count: int = 1
## The total arc in degrees (e.g., 45 degrees for a 3-shot spread)
@export var spread_angle: float = 0.0 

func execute_effect(actor: Node2D, target_dir: Vector2, slot_data: Dictionary) -> void:
	if not projectile_scene: return
	
	if skill_type == SkillType.TAP:
		_fire(actor, target_dir)
	
	elif skill_type == SkillType.HOLD_CONTINUOUS:
		# Fire the "Initial Shot" immediately so it syncs with the wind-up finishing
		_fire(actor, target_dir)
		# Initialize the timer to the full rate so the second shot waits correctly
		slot_data["fire_timer"] = fire_rate
		
	elif skill_type == SkillType.HOLD_CHARGE:
		slot_data["charge_time"] = 0.0

func execute_process(actor: Node2D, delta: float, slot_data: Dictionary) -> void:
	if skill_type == SkillType.HOLD_CONTINUOUS:
		var timer = slot_data.get("fire_timer", 0.0)
		
		# "delta" here is actually "scaled_delta" from the handler
		timer -= delta 
		
		if timer <= 0.0:
			_fire(actor, (actor.get_global_mouse_position() - actor.global_position).normalized())
			timer = fire_rate
			
		slot_data["fire_timer"] = timer
		
	elif skill_type == SkillType.HOLD_CHARGE:
		slot_data["charge_time"] = slot_data.get("charge_time", 0.0) + delta

func execute_release(actor: Node2D, slot_data: Dictionary) -> void:
	if skill_type == SkillType.HOLD_CHARGE:
		var charge = slot_data.get("charge_time", 0.0)
		var mult = 1.0 + minf(charge * 1.5, 3.0)
		_fire(actor, (actor.get_global_mouse_position() - actor.global_position).normalized(), mult, false)
		slot_data["charge_time"] = 0.0

func _fire(actor: Node2D, dir: Vector2, dmg_mult: float = 1.0, override_pierce: bool = false) -> void:
	if not projectile_scene: return
	
	var base_angle = dir.angle()
	var spread_rad = deg_to_rad(spread_angle)
	
	# Calculate starting angle to center the spread
	var start_angle = base_angle
	var angle_step = 0.0
	if projectile_count > 1:
		start_angle = base_angle - (spread_rad / 2.0)
		angle_step = spread_rad / (projectile_count - 1)
		
	var entities_node = PoolManager.get_tree().current_scene.find_child("Entities", true, false)
	
	for i in projectile_count:
		var current_angle = base_angle if projectile_count == 1 else start_angle + (i * angle_step)
		var final_dir = Vector2.RIGHT.rotated(current_angle)
		
		var proj = PoolManager.acquire(projectile_scene)
		if not proj or not proj.has_method("init_projectile"): continue
		
		if entities_node:
			if proj.get_parent(): proj.get_parent().remove_child(proj)
			entities_node.add_child(proj)
			
		var final_stats = StatBlock.new()
		if actor.has_node("StatManager"):
			var sm = actor.get_node("StatManager")
			final_stats.damage_multiplier = sm.final_damage_multiplier
			final_stats.knockback_resistance = sm.final_knockback_resistance
			
		var p = is_piercing or override_pierce
		var applied = self.duplicate() as SkillCommand
		applied.base_damage *= dmg_mult
		
		proj.init_projectile(
			actor.global_position, 
			final_dir, # Use the rotated direction
			speed, 
			p, 
			applied, 
			final_stats, 
			collision_layer, 
			collision_mask
		)
