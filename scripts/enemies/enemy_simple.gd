class_name EnemySimple
extends EnemyBase

var player: Player
var _is_chasing: bool = false

func _ready() -> void:
	super()
	state_chart = $StateChart
	
	var root = state_chart.get_node("Root")
	root.get_node("Chase").state_entered.connect(func(): _is_chasing = true)
	root.get_node("Chase").state_exited.connect(func(): _is_chasing = false)

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
