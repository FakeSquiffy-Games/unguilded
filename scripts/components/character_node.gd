class_name CharacterNode
extends Node

var data: CharacterData
var stat_manager: StatManager
var skill_handler: SkillHandler

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
	
	skill_handler.setup(p_actor, data.character_name, stat_manager)

func process_background(delta: float) -> void:
	skill_handler.process_background(delta, stat_manager.final_casting_multiplier)
