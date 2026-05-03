class_name ProjectileCommand
extends SkillCommand

@export var projectile_scene: PackedScene
@export var speed: float = 800.0
@export var is_piercing: bool = false
@export var fire_rate: float = 0.12 # Used for HOLD_CONTINUOUS

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
		_fire(actor, (actor.get_global_mouse_position() - actor.global_position).normalized(), mult, true)
		slot_data["charge_time"] = 0.0

func _fire(actor: Node2D, dir: Vector2, dmg_mult: float = 1.0, override_pierce: bool = false) -> void:
	if not projectile_scene: return
	var proj = PoolManager.acquire(projectile_scene)
	if not proj or not proj.has_method("init_projectile"): return
	
	var stats = actor.get("stat_manager")
	var base_stats = stats.base_stats if stats else StatBlock.new()
	var p = is_piercing or override_pierce
	
	var applied = self.duplicate() as SkillCommand
	applied.base_damage *= dmg_mult
	
	# init_projectile no longer needs pool_name
	proj.init_projectile(actor.global_position, dir, speed, p, applied, base_stats)
