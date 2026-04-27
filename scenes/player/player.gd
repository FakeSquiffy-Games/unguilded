class_name Player
extends CharacterBody2D

@onready var stat_manager: StatManager = $StatManager
@onready var sprite: Sprite2D = $Sprite2D

var current_health: int
var current_energy: float

func _ready() -> void:
	stat_manager.stats_changed.connect(_on_stats_changed)
	
	# Initialize resource pools
	current_health = stat_manager.final_max_health
	current_energy = stat_manager.final_energy_max
	
	# Notify HUD of initial state
	Events.player_health_changed.emit(current_health, stat_manager.final_max_health)
	Events.player_energy_changed.emit(current_energy, stat_manager.final_energy_max)

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_rotation()
	_handle_energy_regen(delta)

func _handle_movement() -> void:
	# Using Godot's built-in UI actions for WASD/Arrow keys
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * stat_manager.final_speed
	move_and_slide()

func _handle_rotation() -> void:
	var mouse_pos := get_global_mouse_position()
	# Rotate the sprite to face the mouse, keeping the collision/body axis fixed.
	# Subtracting PI/2 assumes the sprite is drawn facing "up". Adjust if drawn facing "right".
	sprite.rotation = (mouse_pos - global_position).angle() + (PI / 2.0)

func _handle_energy_regen(delta: float) -> void:
	if current_energy < stat_manager.final_energy_max:
		current_energy = minf(stat_manager.final_energy_max, current_energy + (stat_manager.final_energy_regen * delta))
		Events.player_energy_changed.emit(current_energy, stat_manager.final_energy_max)

func _on_stats_changed() -> void:
	# Clamp health if max health drops below current health (e.g., losing a buff)
	if current_health > stat_manager.final_max_health:
		current_health = stat_manager.final_max_health
		Events.player_health_changed.emit(current_health, stat_manager.final_max_health)
