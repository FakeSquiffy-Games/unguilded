class_name WaveManager
extends Node

@export_group("Wave Definitions")
@export var wave_rules: Array[WaveSpawnRule] =[]

@export_group("References")
@export var state_chart: StateChart
@export var spawn_points_parent: Node2D

var current_wave: int = 0
var target_wave_points: int = 0
var remaining_wave_points: int = 0

var active_enemy_count: int = 0 
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0

const MAX_CONCURRENT: int = 50 # Soft cap for performance

func _ready() -> void:
	if not state_chart or not spawn_points_parent: return
	Events.enemy_died.connect(_on_enemy_died)
	Events.resume_wave_sequence.connect(func(): state_chart.send_event("setup_next_wave"))
	
	_connect_state("Waiting", _on_waiting_entered)
	_connect_state("Spawning", func(): pass, _on_spawning_processing)
	_connect_state("WaveCleared", _on_wave_cleared_entered)

func _connect_state(state_name: String, entered: Callable = Callable(), processing: Callable = Callable()) -> void:
	var state = state_chart.find_child(state_name, true, false)
	if state:
		if not entered.is_null(): state.state_entered.connect(entered)
		if not processing.is_null(): state.state_processing.connect(processing)

func _on_waiting_entered() -> void:
	current_wave += 1
	active_enemy_count = 0
	
	var rule = _get_active_rule(current_wave)
	if rule:
		target_wave_points = rule.get_wave_budget(current_wave)
		remaining_wave_points = target_wave_points
	else:
		target_wave_points = 50 # Fallback
		remaining_wave_points = 50
	
	Events.wave_started.emit(current_wave)
	print("[WaveManager] Wave ", current_wave, " | Budget: ", target_wave_points, " pts")
	
	get_tree().create_timer(2.0).timeout.connect(func(): state_chart.send_event("start_wave"))

func _on_spawning_processing(delta: float) -> void:
	if remaining_wave_points <= 0:
		if active_enemy_count <= 0:
			state_chart.send_event("wave_complete")
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		# Randomize interval slightly for organic pacing
		spawn_timer = randf_range(0.8, 1.5)
		_try_spawn_enemy()

func _try_spawn_enemy() -> void:
	if active_enemy_count >= MAX_CONCURRENT: return
	
	var rule = _get_active_rule(current_wave)
	if not rule: return
	
	# --- BATCH SPAWN LOGIC (10% Chance) ---
	if randf() < 0.10:
		var cheapest_scene = rule.get_cheapest_scene()
		if cheapest_scene:
			var cost = rule.enemy_costs[cheapest_scene]
			if cost <= remaining_wave_points:
				_execute_batch_spawn(cheapest_scene, cost)
				return
				
	# --- NORMAL SPAWN LOGIC ---
	var valid_scenes = rule.get_valid_spawns(remaining_wave_points)
	
	# Safety Net: Leftover Point Resolution
	if valid_scenes.is_empty():
		remaining_wave_points = 0
		return
		
	var chosen_scene = valid_scenes.pick_random()
	var chosen_cost = rule.enemy_costs[chosen_scene]
	
	_spawn_specific_enemy(chosen_scene, chosen_cost)

func _execute_batch_spawn(scene: PackedScene, cost: int) -> void:
	# Calculate batch size: 25% to 50% of the TOTAL wave budget
	var batch_budget = int(target_wave_points * randf_range(0.25, 0.50))
	var desired_count = batch_budget / cost
	
	# Apply performance and mathematical caps
	var max_by_budget = remaining_wave_points / cost
	var max_by_swarm_limit = MAX_CONCURRENT - active_enemy_count
	var absolute_cap = MAX_CONCURRENT / 2 # Hard cap batch to 25
	
	var final_count = min(desired_count, min(max_by_budget, min(max_by_swarm_limit, absolute_cap)))
	
	if final_count > 0:
		print("[WaveManager] Swarm Event! Spawning batch of ", final_count)
		for i in final_count:
			_spawn_specific_enemy(scene, cost)

func _spawn_specific_enemy(scene: PackedScene, cost: int) -> void:
	var points = spawn_points_parent.get_children()
	var sp = points.pick_random() as Node2D
	
	var enemy = PoolManager.acquire(scene) as Actor
	
	var entities_node = get_tree().current_scene.find_child("Entities", true, false)
	if entities_node and enemy.get_parent() != entities_node:
		if enemy.get_parent():
			enemy.get_parent().remove_child(enemy)
		entities_node.add_child(enemy)
	
	enemy.global_position = sp.global_position
	enemy.add_to_group("enemies") 
	
	# FLATTENED STATS: No multipliers, we use the raw base stats
	enemy.revive() 
	
	remaining_wave_points -= cost
	active_enemy_count += 1

func _get_active_rule(wave: int) -> WaveSpawnRule:
	for rule in wave_rules:
		if wave >= rule.min_wave and wave <= rule.max_wave:
			return rule
	return null

func _on_enemy_died(_enemy: Node) -> void:
	active_enemy_count -= 1
	if remaining_wave_points <= 0 and active_enemy_count <= 0:
		state_chart.send_event("wave_complete")

func _on_wave_cleared_entered() -> void:
	print("[WaveManager] Wave ", current_wave, " Cleared! Waiting for Player Loot...")
	Events.wave_cleared.emit(current_wave)
