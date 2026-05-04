class_name WaveManager
extends Node

@export_group("Wave Definitions")
@export var wave_rules: Array[WaveSpawnRule] =[]

@export_group("References")
@export var state_chart: StateChart
@export var spawn_points_parent: Node2D

var current_wave: int = 0
var enemy_stat_multiplier: float = 1.0
var total_enemies_to_spawn: int = 0
var enemies_spawned: int = 0
var max_concurrent: int = 5

var active_enemy_count: int = 0 
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5

func _ready() -> void:
	if not state_chart or not spawn_points_parent: return
	Events.enemy_died.connect(_on_enemy_died)
	
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
	enemy_stat_multiplier = 1.0 + (current_wave * 0.12)
	total_enemies_to_spawn = 5 + (current_wave * 3)
	enemies_spawned = 0
	active_enemy_count = 0
	max_concurrent = 3 + current_wave
	spawn_interval = maxf(0.3, 1.8 - (current_wave * 0.1))
	spawn_timer = 0.5 
	
	Events.wave_started.emit(current_wave)
	print("[WaveManager] Wave ", current_wave, " Setup Complete. Starting in 2s...")
	
	# Automatically push to Spawning after 2 seconds (Will be replaced by Loot UI later)
	get_tree().create_timer(2.0).timeout.connect(func(): state_chart.send_event("start_wave"))

func _on_spawning_processing(delta: float) -> void:
	if enemies_spawned >= total_enemies_to_spawn:
		if active_enemy_count <= 0:
			state_chart.send_event("wave_complete")
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		_try_spawn_enemy()

func _try_spawn_enemy() -> void:
	if active_enemy_count >= max_concurrent: return
	
	var points = spawn_points_parent.get_children()
	var sp = points.pick_random() as Node2D
	
	var scene_to_spawn = _get_random_enemy_for_wave(current_wave)
	if not scene_to_spawn: return
		
	var enemy = PoolManager.acquire(scene_to_spawn) as Actor
	
	# Safe Reparenting (Avoids triggering _exit_tree if already in Entities)
	var entities_node = get_tree().current_scene.find_child("Entities", true, false)
	if entities_node and enemy.get_parent() != entities_node:
		if enemy.get_parent():
			enemy.get_parent().remove_child(enemy)
		entities_node.add_child(enemy)
	
	enemy.global_position = sp.global_position
	enemy.add_to_group("enemies") 
	
	var base = enemy.stat_manager.base_stats
	var scaled = StatBlock.new()
	scaled.max_health = int(base.max_health * enemy_stat_multiplier)
	scaled.move_speed = base.move_speed * (1.0 + (current_wave * 0.01))
	scaled.damage_multiplier = base.damage_multiplier * enemy_stat_multiplier
	
	enemy.revive(scaled)
	enemies_spawned += 1
	active_enemy_count += 1

func _get_random_enemy_for_wave(wave: int) -> PackedScene:
	for rule in wave_rules:
		if wave >= rule.min_wave and wave <= rule.max_wave:
			return rule.get_random_enemy()
	return null

func _on_enemy_died(_enemy: Node) -> void:
	active_enemy_count -= 1
	if enemies_spawned >= total_enemies_to_spawn and active_enemy_count <= 0:
		state_chart.send_event("wave_complete")

func _on_wave_cleared_entered() -> void:
	Events.wave_cleared.emit(current_wave)
	print("[WaveManager] Wave ", current_wave, " Cleared!")
	
	get_tree().create_timer(2.0).timeout.connect(func(): state_chart.send_event("setup_next_wave"))
