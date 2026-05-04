class_name EnemyBrain
extends Node

@onready var actor: Actor = get_parent()
var player: Node2D

func _ready() -> void:
	await actor.ready
	actor.death_animation_finished.connect(_on_death_finished)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player): return
		actor.add_collision_exception_with(player)

func _on_death_finished() -> void:
	Events.enemy_died.emit(actor)
	PoolManager.release(actor)
	# Clean up collision for next pool use
	actor.get_node("CollisionShape2D").set_deferred("disabled", false)
