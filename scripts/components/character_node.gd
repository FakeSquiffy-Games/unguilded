class_name CharacterNode
extends Node

var data: CharacterData
var stat_manager: StatManager
var skill_handler: SkillHandler

# Tracks the current integer level of each slot (0 = Locked)
var slot_levels: Dictionary = {
	"left_tap": 1, # Always starts unlocked
	"left_hold": 0,
	"right_tap": 0,
	"right_hold": 0
}

func setup(p_data: CharacterData, p_actor: Node2D) -> void:
	data = p_data
	
	stat_manager = StatManager.new()
	stat_manager.base_stats = data.base_stats
	add_child(stat_manager)
	
	skill_handler = SkillHandler.new()
	skill_handler.emits_hud_events = true 
	
	# Load the initial skills based on starting levels
	_apply_skill_tier("left_tap")
	_apply_skill_tier("left_hold")
	_apply_skill_tier("right_tap")
	_apply_skill_tier("right_hold")
	
	add_child(skill_handler)
	skill_handler.setup(p_actor, data.character_name, stat_manager)

func process_background(delta: float) -> void:
	skill_handler.process_background(delta, stat_manager.final_casting_multiplier)

func upgrade_slot(slot_name: String) -> bool:
	var tiers: Array = data.get(slot_name + "_tiers")
	if slot_levels[slot_name] >= tiers.size():
		return false # Maxed out!
		
	slot_levels[slot_name] += 1
	_apply_skill_tier(slot_name)
	return true

func _apply_skill_tier(slot_name: String) -> void:
	var lvl = slot_levels[slot_name]
	var tiers = data.get(slot_name + "_tiers")
	
	# If locked (0) or missing data, assign null
	if lvl == 0 or lvl > tiers.size() or tiers.is_empty():
		skill_handler.set(slot_name, null)
	else:
		# Arrays are 0-indexed, so Level 1 is Index 0
		skill_handler.set(slot_name, tiers[lvl - 1])
		
	# Hot-swap it into the dictionary if it's already running
	if skill_handler.slots.has(slot_name):
		skill_handler.slots[slot_name].command = skill_handler.get(slot_name)
