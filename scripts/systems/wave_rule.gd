class_name WaveSpawnRule
extends Resource

@export var min_wave: int = 1
@export var max_wave: int = 999

## Map of Enemy Scenes to their Relative Weights
@export var enemy_weights: Dictionary[PackedScene, float] = {} # Key: PackedScene, Value: float (Weight)

func get_random_enemy() -> PackedScene:
	if enemy_weights.is_empty(): return null
	
	var total_weight: float = 0.0
	for weight in enemy_weights.values():
		total_weight += weight
		
	var roll = randf() * total_weight
	var current_sum: float = 0.0
	
	for scene in enemy_weights.keys():
		current_sum += enemy_weights[scene]
		if roll <= current_sum:
			return scene as PackedScene
			
	return enemy_weights.keys()[0] # Fallback
