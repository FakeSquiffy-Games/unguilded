class_name ProjectileBase
extends CharacterBody2D

var pool_name: StringName
var direction: Vector2 = Vector2.ZERO
var speed: float = 800.0
var piercing: bool = false
var skill_data: SkillAction
var attacker_stats: StatBlock

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	screen_notifier.screen_exited.connect(_on_screen_exited)

func init_projectile(p_pool_name: StringName, p_pos: Vector2, p_dir: Vector2, p_speed: float, p_piercing: bool, p_skill: SkillAction, p_stats: StatBlock) -> void:
	pool_name = p_pool_name
	global_position = p_pos
	direction = p_dir.normalized()
	speed = p_speed
	piercing = p_piercing
	skill_data = p_skill
	attacker_stats = p_stats
	rotation = direction.angle() + (PI / 2.0)
	z_index = 10

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(direction * speed * delta)
	if collision:
		var collider := collision.get_collider()
		
		# Duck-typing: If it has a take_damage method, it's an enemy/destructible
		if collider.has_method("take_damage"):
			var result := CombatResolver.resolve(attacker_stats, skill_data, null, direction)
			collider.take_damage(result)
			if not piercing:
				PoolManager.release(pool_name, self)
		elif not collider is Player:
			# Hit a wall/arena boundary (and it's not the player)
			PoolManager.release(pool_name, self)

func _on_screen_exited() -> void:
	# Recycles the projectile when it leaves the camera view
	PoolManager.release(pool_name, self)
