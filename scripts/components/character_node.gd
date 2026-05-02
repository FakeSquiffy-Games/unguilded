class_name CharacterNode
extends Node

var data: CharacterData
var stat_manager: StatManager
var skill_handler: SkillHandler

# Energy is independent per character!
var current_energy: float = 0.0 

func setup(p_data: CharacterData, p_actor: Node2D) -> void:
	data = p_data
	
	stat_manager = StatManager.new()
	stat_manager.base_stats = data.base_stats
	add_child(stat_manager)
	
	skill_handler = SkillHandler.new()
	skill_handler.left_tap = data.left_tap
	skill_handler.left_hold = data.left_hold
	skill_handler.right_tap = data.right_tap
	skill_handler.right_hold = data.right_hold
	add_child(skill_handler)
	skill_handler.setup(p_actor)
	
	current_energy = stat_manager.final_energy_max

func process_background(delta: float) -> void:
	# Regenerate energy in the background
	if current_energy < stat_manager.final_energy_max:
		current_energy = minf(stat_manager.final_energy_max, current_energy + (stat_manager.final_energy_regen * delta))
