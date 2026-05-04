class_name SkillHandler
extends Node

class SkillSlot:
	var command: SkillCommand
	var current_energy: float = 100.0
	var max_energy: float = 100.0
	var slot_data: Dictionary = {}

@export var emits_hud_events: bool = false # Set to true only for Player Actors
@export var left_tap: SkillCommand
@export var left_hold: SkillCommand
@export var right_tap: SkillCommand
@export var right_hold: SkillCommand

var slots: Dictionary = {}
var actor: Node2D 
var character_name: StringName
var stat_manager: StatManager

func setup(p_actor: Node2D, p_char_name: StringName, p_stat_manager: StatManager) -> void:
	actor = p_actor
	character_name = p_char_name
	stat_manager = p_stat_manager
	_init_slot("left_tap", left_tap)
	_init_slot("left_hold", left_hold)
	_init_slot("right_tap", right_tap)
	_init_slot("right_hold", right_hold)

func _init_slot(slot_name: String, cmd: SkillCommand) -> void:
	var slot = SkillSlot.new()
	slot.command = cmd
	slots[slot_name] = slot

func process_background(delta: float, casting_multiplier: float) -> void:
	for slot_name in slots:
		var slot: SkillSlot = slots[slot_name]
		if slot.command and slot.current_energy < slot.max_energy:
			slot.current_energy = minf(slot.max_energy, slot.current_energy + (slot.command.base_regen * casting_multiplier * delta))
			if emits_hud_events:
				Events.skill_energy_updated.emit(character_name, slot_name, slot.current_energy, slot.max_energy)

func validate_and_pay(action_name: String) -> bool:
	var slot: SkillSlot = slots.get(action_name)
	if not slot or not slot.command: return false
	var cmd = slot.command
	
	if cmd.skill_type == SkillCommand.SkillType.TAP or cmd.skill_type == SkillCommand.SkillType.HOLD_CHARGE:
		if slot.current_energy < cmd.energy_requirement: return false
		slot.current_energy -= cmd.energy_requirement
	else:
		# Require enough energy for at least 0.3 seconds of continuous fire to prevent "twitching"
		var min_activation_cost = cmd.energy_requirement * 0.3
		if slot.current_energy < min_activation_cost: 
			return false
	
	if emits_hud_events:
		Events.skill_energy_updated.emit(character_name, action_name, slot.current_energy, slot.max_energy)
	return true

func execute_effect(action_name: String, target_dir: Vector2) -> void:
	var slot: SkillSlot = slots.get(action_name)
	if slot and slot.command:
		slot.command.execute_effect(actor, target_dir, slot.slot_data)

func try_execute_process(action_name: String, delta: float) -> bool:
	var slot: SkillSlot = slots.get(action_name)
	if not slot or not slot.command: return false
	var cmd = slot.command
	
	var mult: float = stat_manager.final_casting_multiplier
	var scaled_delta: float = delta * mult
	
	if cmd.skill_type == SkillCommand.SkillType.HOLD_CONTINUOUS:
		var frame_cost = cmd.energy_requirement * scaled_delta
		
		# The Jam Check. Return false if we can't afford this frame.
		if slot.current_energy < frame_cost: 
			return false 
			
		slot.current_energy -= frame_cost
		if character_name != &"" and character_name != &"Enemy":
			Events.skill_energy_updated.emit(character_name, action_name, slot.current_energy, slot.max_energy)
		
	cmd.execute_process(actor, scaled_delta, slot.slot_data)
	return true

func try_execute_release(action_name: String) -> void:
	var slot: SkillSlot = slots.get(action_name)
	if not slot or not slot.command: return
	slot.command.execute_release(actor, slot.slot_data)
