class_name SkillHandler
extends Node
## Universal handler that executes SkillCommands and manages cooldowns.

@export var left_tap: SkillCommand
@export var left_hold: SkillCommand
@export var right_tap: SkillCommand
@export var right_hold: SkillCommand

var cooldowns: Dictionary = {
	"left_tap": 0.0, "left_hold": 0.0, 
	"right_tap": 0.0, "right_hold": 0.0
}

var actor: Node2D

func setup(p_actor: Node2D) -> void:
	actor = p_actor

func _process(delta: float) -> void:
	for action in cooldowns.keys():
		if cooldowns[action] > 0.0:
			cooldowns[action] = maxf(0.0, cooldowns[action] - delta)

func try_execute_start(action_name: String, target_dir: Vector2) -> SkillCommand:
	var skill = get(action_name) as SkillCommand
	if not skill: return null
	
	if cooldowns[action_name] > 0.0: return null
	
	# Energy check (if the actor has energy)
	if "current_energy" in actor:
		if actor.current_energy < skill.energy_cost:
			return null
		actor.current_energy -= skill.energy_cost
		Events.player_energy_changed.emit(actor.current_energy, actor.stat_manager.final_energy_max)

	cooldowns[action_name] = skill.cooldown
	skill.execute_start(actor, target_dir)
	return skill

func try_execute_process(action_name: String, delta: float) -> void:
	var skill = get(action_name) as SkillCommand
	if skill: skill.execute_process(actor, delta)

func try_execute_release(action_name: String) -> void:
	var skill = get(action_name) as SkillCommand
	if skill: skill.execute_release(actor)
