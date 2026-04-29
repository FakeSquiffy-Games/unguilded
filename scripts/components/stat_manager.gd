class_name StatManager
extends Node
## Component responsible for computing final stats from base values and modifiers.

signal stats_changed

@export var base_stats: StatBlock

var modifiers: Array[StatBlock] =[]

# Computed final stats
var final_max_health: int
var final_speed: float
var final_energy_max: float
var final_energy_regen: float
var final_damage_multiplier: float
var final_cooldown_reduction: float

func _ready() -> void:
	if not base_stats:
		# Fallback to prevent crashes if forgotten in inspector
		base_stats = StatBlock.new() 
	_recalculate()

func add_modifier(block: StatBlock) -> void:
	modifiers.append(block)
	_recalculate()

func remove_modifier(block: StatBlock) -> void:
	modifiers.erase(block)
	_recalculate()

func _recalculate() -> void:
	# Start from the base values
	final_max_health = base_stats.max_health
	final_speed = base_stats.move_speed
	final_energy_max = base_stats.energy_max
	final_energy_regen = base_stats.energy_regen
	final_damage_multiplier = base_stats.damage_multiplier
	final_cooldown_reduction = base_stats.cooldown_reduction
	
	# Accumulate modifiers
	for mod in modifiers:
		final_max_health += mod.max_health
		final_speed += mod.move_speed
		final_energy_max += mod.energy_max
		final_energy_regen += mod.energy_regen
		final_damage_multiplier += mod.damage_multiplier
		final_cooldown_reduction += mod.cooldown_reduction
	
	stats_changed.emit()
