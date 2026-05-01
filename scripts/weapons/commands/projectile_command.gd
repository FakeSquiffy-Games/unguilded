class_name ProjectileCommand
extends SkillCommand

@export var projectile_scene: PackedScene
@export var speed: float = 800.0
@export var is_piercing: bool = false
@export var pool_name: StringName = &"arrow_pool"

func execute_start(actor: Node2D, target_dir: Vector2) -> void:
	if not projectile_scene: return
	
	# Register pool lazily if it doesn't exist
	PoolManager.register_pool(pool_name, projectile_scene, 20)
	
	var proj = PoolManager.acquire(pool_name)
	if not proj or not proj.has_method("init_projectile"): return
	
	# Pass the skill's data to the projectile
	var stats = actor.get("stat_manager") # Duck typing to allow enemies/players to use this
	var base_stats = stats.base_stats if stats else StatBlock.new()
	
	proj.init_projectile(pool_name, actor.global_position, target_dir, speed, is_piercing, self, base_stats)
