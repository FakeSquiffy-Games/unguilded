class_name BuffCommand
extends SkillCommand

@export_group("Restoration")
@export var heal_amount: int = 0

@export_group("Temporary Buffs")
@export var buff_stats: StatBlock
@export var buff_duration: float = 5.0

func execute_effect(actor: Node2D, _target_dir: Vector2, _slot_data: Dictionary) -> void:
	if not actor is Actor: return
	
	# Apply Healing
	if heal_amount > 0:
		actor.current_health = min(actor.max_health, actor.current_health + heal_amount)
		
	# Apply Stat Buff
	if buff_stats and actor.stat_manager:
		actor.stat_manager.add_modifier(buff_stats)
		
		# Create a safe timer to remove the buff
		var timer = actor.get_tree().create_timer(buff_duration)
		timer.timeout.connect(func():
			if is_instance_valid(actor) and is_instance_valid(actor.stat_manager):
				actor.stat_manager.remove_modifier(buff_stats)
		)
