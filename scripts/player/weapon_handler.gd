class_name WeaponHandler
extends Node

@export var progression: ProgressionComponent
@onready var player: Player = owner

# Grab the sibling node directly instead of waiting for parent's @onready
@onready var input_handler: InputHandler = owner.get_node("InputHandler")

# Weapon mapping to executors
@onready var executors: Dictionary = {
	&"weapon_projectile": $ProjectileExecutor,
	&"weapon_aoe": $AOEExecutor,
	&"weapon_melee": $MeleeExecutor,
	&"weapon_energy": $EnergyExecutor
}

var weapon_slots: Array[WeaponResource] = [null, null, null]
var active_slot_index: int = 0

# Cooldown tracking: { slot_index: { "left_tap": remaining_time } }
var cooldowns: Dictionary = {0: {}, 1: {}, 2: {}}

func _ready() -> void:
	# Wire up input handler signals directly
	input_handler.left_tap_triggered.connect(_try_execute_tap.bind("left_tap"))
	input_handler.right_tap_triggered.connect(_try_execute_tap.bind("right_tap"))
	
	input_handler.left_hold_active.connect(_try_execute_hold_active.bind("left_hold"))
	input_handler.right_hold_active.connect(_try_execute_hold_active.bind("right_hold"))
	
	input_handler.left_hold_released.connect(_try_execute_hold_release.bind("left_hold"))
	input_handler.right_hold_released.connect(_try_execute_hold_release.bind("right_hold"))

func _process(delta: float) -> void:
	_process_cooldowns(delta)

func set_active_weapon(index: int) -> void:
	if index < 0 or index >= weapon_slots.size(): return
	if weapon_slots[index] == null:
		print("Slot ", index, " is empty!")
		return
	active_slot_index = index
	Events.weapon_switched.emit(active_slot_index)

func _get_active_weapon() -> WeaponResource:
	return weapon_slots[active_slot_index]

func _get_skill(weapon: WeaponResource, action_name: String) -> SkillAction:
	match action_name:
		"left_tap": return weapon.left_tap
		"left_hold": return weapon.left_hold
		"right_tap": return weapon.right_tap
		"right_hold": return weapon.right_hold
	return null

func _can_execute(weapon: WeaponResource, skill: SkillAction, action_name: String) -> bool:
	if not player.can_attack: return false
	if not skill: return false
	if not progression.has_slot_unlocked(weapon, action_name):
		print("LOCKED: ", action_name)
		return false
	if cooldowns[active_slot_index].get(action_name, 0.0) > 0.0:
		return false
	if player.current_energy < skill.energy_cost:
		print("NOT ENOUGH ENERGY!")
		return false
	return true

func _try_execute_tap(action_name: String) -> void:
	var weapon := _get_active_weapon()
	if not weapon: return
	var skill := _get_skill(weapon, action_name)
	
	if _can_execute(weapon, skill, action_name):
		# Start Cooldown
		cooldowns[active_slot_index][action_name] = skill.cooldown
		# Drain Energy
		player.current_energy -= skill.energy_cost
		Events.player_energy_changed.emit(player.current_energy, player.stat_manager.final_energy_max)
		# Trigger FSM
		player.active_skill = skill
		player.state_chart.send_event("skill_requested")
		# Execute
		executors[weapon.weapon_id].execute_tap(skill, action_name)

func _try_execute_hold_active(delta: float, action_name: String) -> void:
	var weapon := _get_active_weapon()
	if not weapon: return
	var skill := _get_skill(weapon, action_name)
	
	# Bypasses FSM check because hold is a continuous channel
	if skill and progression.has_slot_unlocked(weapon, action_name):
		if skill.is_energy_drain:
			var drain := skill.energy_cost * delta
			if player.current_energy < drain:
				return # Stop firing if out of energy
			player.current_energy -= drain
			Events.player_energy_changed.emit(player.current_energy, player.stat_manager.final_energy_max)
		executors[weapon.weapon_id].execute_hold_active(skill, action_name, delta)

func _try_execute_hold_release(action_name: String) -> void:
	var weapon := _get_active_weapon()
	if not weapon: return
	var skill := _get_skill(weapon, action_name)
	if skill and progression.has_slot_unlocked(weapon, action_name):
		executors[weapon.weapon_id].execute_hold_release(skill, action_name)

func _process_cooldowns(delta: float) -> void:
	for slot in cooldowns.keys():
		for action in cooldowns[slot].keys():
			if cooldowns[slot][action] > 0:
				cooldowns[slot][action] -= delta
				if cooldowns[slot][action] < 0: cooldowns[slot][action] = 0
				
				# Only emit UI updates for the active slot to save performance
				if slot == active_slot_index:
					var total: float = _get_skill(weapon_slots[slot], action).cooldown
					Events.cooldown_updated.emit(slot, action, cooldowns[slot][action], total)
