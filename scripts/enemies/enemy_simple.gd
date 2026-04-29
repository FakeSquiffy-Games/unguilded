class_name EnemySimple
extends EnemyBase

var player: Player
var _is_chasing: bool = false
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	super()
	state_chart = $StateChart
	
	var root = state_chart.get_node("Root")
	root.get_node("Chase").state_entered.connect(func(): _is_chasing = true)
	root.get_node("Chase").state_exited.connect(func(): _is_chasing = false)
	
	hurtbox.body_entered.connect(_on_hurtbox_entered)

func _physics_process(delta: float) -> void:
	super(delta)
	
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player
		if not is_instance_valid(player): return
		
		# FIX: Tell the physics engine not to let this enemy body-block the player
		add_collision_exception_with(player)

	if _is_chasing:
		var dir = (player.global_position - global_position).normalized()
		velocity = velocity.move_toward(dir * stat_manager.final_speed, 1500 * delta)

func _on_hurtbox_entered(body: Node2D) -> void:
	if body == player:
		print("[EnemySimple] Dealt Contact Damage!")
		Events.player_hit.emit() 
		
		player.current_health -= 10
		Events.player_health_changed.emit(player.current_health, player.stat_manager.final_max_health)
		
		# FIX: Combat Recoil. Bounce the enemy directly away from the player
		var bounce_dir := (global_position - player.global_position).normalized()
		velocity = bounce_dir * 600.0 # Apply an instant burst of knockback
		
		# Send the enemy into Hitstun for 0.3s so it stops chasing momentarily
		state_chart.send_event("took_damage")
