class_name StatManager
extends Node

@export var base_stats: StatBlock
var modifiers: Array[StatBlock] =[]

var final_max_health: int
var final_speed: float
var final_damage_multiplier: float
var final_casting_multiplier: float
var final_knockback_resistance: float

func _ready() -> void:
	if not base_stats: base_stats = StatBlock.new() 
	_recalculate()

func add_modifier(block: StatBlock) -> void:
	modifiers.append(block)
	_recalculate()

func remove_modifier(block: StatBlock) -> void:
	modifiers.erase(block)
	_recalculate()

func _recalculate() -> void:
	final_max_health = base_stats.max_health
	final_speed = base_stats.move_speed
	final_damage_multiplier = base_stats.damage_multiplier
	final_casting_multiplier = base_stats.casting_multiplier
	final_knockback_resistance = base_stats.knockback_resistance
	
	for mod in modifiers:
		final_max_health += mod.max_health
		final_speed += mod.move_speed
		final_damage_multiplier += mod.damage_multiplier
		final_casting_multiplier += mod.casting_multiplier
		final_knockback_resistance += mod.knockback_resistance
	
	final_knockback_resistance = clampf(final_knockback_resistance, 0.0, 1.0)
	Events.stats_changed.emit()
