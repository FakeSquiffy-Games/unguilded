class_name ProjectileBase
extends CharacterBody2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 800.0
var piercing: bool = false
var skill_data: SkillCommand
var attacker_stats: StatBlock

var is_active_projectile: bool = false # The elegant lifecycle lock
var lifetime_timer: float = 0.0 # Failsafe

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	screen_notifier.screen_exited.connect(_on_screen_exited)

# Update the init_projectile signature:
func init_projectile(p_pos: Vector2, p_dir: Vector2, p_speed: float, p_piercing: bool, p_skill: SkillCommand, p_stats: StatBlock, p_layer: int, p_mask: int) -> void:
	global_position = p_pos
	direction = p_dir.normalized()
	speed = p_speed
	piercing = p_piercing
	skill_data = p_skill
	attacker_stats = p_stats
	z_index = 10
	
	# FIX: Apply injected physics identity
	collision_layer = p_layer
	collision_mask = p_mask
	
	rotation = direction.angle()
	sprite.flip_h = false 
	sprite.play("default")
	sprite.set_frame_and_progress(0, 0.0)
	
	is_active_projectile = true
	lifetime_timer = 5.0

func _physics_process(delta: float) -> void:
	if not is_active_projectile: return
	
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		_despawn()
		return
	
	var collision := move_and_collide(direction * speed * delta)
	if collision:
		var collider := collision.get_collider()
		
		# Obstacle check
		if collider is TileMapLayer:
			var collision_mask = collider.tile_set.get_physics_layer_collision_layer(0)
			if collision_mask & 4 != 0:
				_despawn()
				return
		else:
			if collider.collision_layer & 4 != 0: 
				_despawn()
				return
		
		# Interface check (Now works for both Player and Enemies)
		if collider.has_method("take_damage"):
			var result := CombatResolver.resolve(attacker_stats, skill_data, null, direction)
			collider.take_damage(result)
			
			# If it's not piercing, we despawn immediately so we don't "bump"
			if not piercing: 
				_despawn()

func _on_screen_exited() -> void:
	if not is_active_projectile: return
	_despawn()

func _despawn() -> void:
	is_active_projectile = false # Lock out deferred signals
	PoolManager.release(self)
