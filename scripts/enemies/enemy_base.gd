class_name EnemyBase
extends CharacterBody2D

@onready var stat_manager: StatManager = $StatManager
@onready var sprite: Sprite2D = $Sprite2D

var current_health: int
var state_chart: StateChart # Will be populated by inheriting scenes

func _ready() -> void:
	current_health = stat_manager.final_max_health
	add_to_group("enemies")

func take_damage(result: CombatResolver.CombatResult) -> void:
	current_health -= int(result.final_damage)
	
	# Damage Flash
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Knockback Application
	velocity += result.knockback
	
	# Trigger Hitstun if hit hard enough
	if result.triggered_hitstun and state_chart:
		state_chart.send_event("took_damage")
		
	if current_health <= 0:
		_die()

func _die() -> void:
	Events.enemy_died.emit(self)
	queue_free() # Will be PoolManager.release() in Phase 9

func _physics_process(delta: float) -> void:
	# Base friction naturally slows them down after knockback
	velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
	move_and_slide()
