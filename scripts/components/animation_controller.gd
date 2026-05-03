class_name AnimationController
extends Node

@export var sprite: AnimatedSprite2D
@export var state_chart: StateChart

@onready var player: Player = owner

func _ready() -> void:
	if not sprite or not state_chart: return
	
	# Connect the loop-back signal
	sprite.animation_finished.connect(_on_animation_finished)
	
	var combat = state_chart.get_node("ParallelRoot/CombatRoot")
	combat.get_node("Startup").state_entered.connect(_on_attack_started)
	combat.get_node("Neutral").state_entered.connect(_on_neutral_entered)
	
	var movement = state_chart.get_node("ParallelRoot/MovementRoot")
	movement.get_node("Idle").state_entered.connect(func(): _try_play("idle"))
	movement.get_node("Run").state_entered.connect(func(): _try_play("run"))

func _on_attack_started() -> void:
	var active_char = player.party_manager.get_active()
	if active_char:
		sprite.speed_scale = active_char.stat_manager.final_casting_multiplier
	sprite.play("attack")

func _on_animation_finished() -> void:
	# Logic-Driven Looping:
	# If the animation finished but the FSM is still in the Active state, 
	# it means we are still holding the button for a continuous skill.
	if sprite.animation == &"attack":
		var active_state = state_chart.get_node("ParallelRoot/CombatRoot/Active")
		if active_state.active:
			sprite.play("attack")
			# speed_scale remains set from _on_attack_started

func _on_neutral_entered() -> void:
	sprite.speed_scale = 1.0
	var movement = state_chart.get_node("ParallelRoot/MovementRoot")
	if movement.get_node("Run").active:
		sprite.play("run")
	else:
		sprite.play("idle")

func _try_play(anim_name: String) -> void:
	var combat = state_chart.get_node("ParallelRoot/CombatRoot")
	var is_busy = combat.get_node("Startup").active or combat.get_node("Active").active or combat.get_node("Recovery").active or combat.get_node("Hitstun").active
	if not is_busy:
		sprite.speed_scale = 1.0
		sprite.play(anim_name)
