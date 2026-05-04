class_name AnimationController
extends Node

@export var sprite: AnimatedSprite2D
@export var state_chart: StateChart

@onready var actor: Actor = owner # Explicitly cast to the new Actor base!

func _ready() -> void:
	if not sprite or not state_chart: return
	
	sprite.animation_finished.connect(_on_animation_finished)
	
	var combat = state_chart.get_node("ParallelRoot/CombatRoot")
	combat.get_node("Startup").state_entered.connect(_on_attack_started)
	combat.get_node("Neutral").state_entered.connect(_on_neutral_entered)
	
	combat.get_node("Hitstun").state_entered.connect(func(): sprite.play("hurt"))
	combat.get_node("Death").state_entered.connect(func(): sprite.play("death"))
	
	var movement = state_chart.get_node("ParallelRoot/MovementRoot")
	movement.get_node("Idle").state_entered.connect(func(): _try_play("idle"))
	movement.get_node("Run").state_entered.connect(func(): _try_play("run"))

func _on_attack_started() -> void:
	# Scaling logic uses the Actor's StatManager directly!
	sprite.speed_scale = actor.stat_manager.final_casting_multiplier if actor.stat_manager else 1.0
	sprite.play("attack")

func _on_animation_finished() -> void:
	if sprite.animation == &"attack":
		var active_state = state_chart.get_node("ParallelRoot/CombatRoot/Active")
		if active_state and active_state.active:
			sprite.play("attack")
			
	elif sprite.animation == &"death":
		# We emit a generic signal. The specific Brain (Player vs Slime) 
		# will listen to this and decide what to do (Reload vs Pool Release)
		actor.death_animation_finished.emit()

func _on_neutral_entered() -> void:
	sprite.speed_scale = 1.0
	var movement = state_chart.get_node("ParallelRoot/MovementRoot")
	if movement.get_node("Run").active:
		sprite.play("run")
	else:
		sprite.play("idle")

func _try_play(anim_name: String) -> void:
	var combat = state_chart.get_node("ParallelRoot/CombatRoot")
	var is_busy = combat.get_node("Startup").active or combat.get_node("Active").active or combat.get_node("Recovery").active or combat.get_node("Hitstun").active or combat.get_node("Death").active
	if not is_busy:
		sprite.speed_scale = 1.0
		sprite.play(anim_name)
