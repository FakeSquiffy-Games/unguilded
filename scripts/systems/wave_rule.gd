class_name WaveSpawnRule
extends Resource

@export var min_wave: int = 1
@export var max_wave: int = 999

@export_group("Budget Scaling")
## Base points awarded when this rule is active
@export var base_wave_points: int = 20
## Additional points awarded per wave level
@export var point_per_wave: int = 5

@export_group("Spawns")
## Key: PackedScene (The Enemy), Value: int (The Point Cost)
@export var enemy_costs: Dictionary[PackedScene, int] = {}

func get_wave_budget(current_wave: int) -> int:
	return base_wave_points + (current_wave * point_per_wave)

func get_valid_spawns(budget: int) -> Array[PackedScene]:
	var valid: Array[PackedScene] =[]
	for scene in enemy_costs.keys():
		if enemy_costs[scene] <= budget:
			valid.append(scene)
	return valid

func get_cheapest_scene() -> PackedScene:
	var lowest_cost: int = 999999
	var cheapest_scene: PackedScene = null
	for scene in enemy_costs.keys():
		var cost = enemy_costs[scene]
		if cost < lowest_cost:
			lowest_cost = cost
			cheapest_scene = scene
	return cheapest_scene
