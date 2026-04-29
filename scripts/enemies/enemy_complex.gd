class_name EnemyComplex
extends EnemyBase

@export var attack_range: float = 180.0
var player: Player
var _is_chasing: bool = false

func _ready() -> void:
	super()
	state_chart = $StateChart
	
	var root = state_chart.get_node("Root")
	root.get_node("Chase").state_entered.connect(func(): _is_chasing = true)
	root.get_node("Chase").state_exited.connect(func(): _is_chasing = false)
	
	root.get_node("Telegraph").state_entered.connect(_on_telegraph)
	root.get_node("Telegraph").state_exited.connect(_reset_color)
	
	root.get_node("Attack").state_entered.connect(_on_attack)
	root.get_node("Attack").state_exited.connect(_reset_color)

func _physics_process(delta: float) -> void:
	super(delta)
	
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player
		if not is_instance_valid(player): return
		
		# FIX: Tell the physics engine not to let this enemy body-block the player
		add_collision_exception_with(player)

	if _is_chasing:
		var dist = global_position.distance_to(player.global_position)
		if dist <= attack_range:
			state_chart.send_event("player_in_range")
		else:
			var dir = (player.global_position - global_position).normalized()
			velocity = velocity.move_toward(dir * stat_manager.final_speed, 1500 * delta)

func _on_telegraph() -> void:
	sprite.modulate = Color.ORANGE

func _on_attack() -> void:
	sprite.modulate = Color.RED
	print("[EnemyComplex] Strikes the player!")
	# Phase 11 will spawn a dedicated Area2D hitbox here.

func _reset_color() -> void:
	sprite.modulate = Color.WHITE
