class_name Player
extends CharacterBody2D

@onready var stat_manager: StatManager = $StatManager
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_chart: StateChart = $StateChart
@onready var input_handler: InputHandler = $InputHandler
@onready var progression: ProgressionComponent = $ProgressionComponent
@onready var weapon_handler: WeaponHandler = $WeaponHandler

var current_health: int
var current_energy: float

# FSM & Timing
var _state_timer_tween: Tween
var active_skill: SkillAction # Set by WeaponHandler in Phase 5

# Chrono-Switch
var pending_slot_key: int = -1
var chrono_tween: Tween
const CHRONO_TIME_SCALE: float = 0.3

# Weapon Handler
var can_attack: bool = true # Governed by FSM

func _ready() -> void:
	stat_manager.stats_changed.connect(_on_stats_changed)
	_connect_state_chart()
	
	current_health = stat_manager.final_max_health
	current_energy = stat_manager.final_energy_max
	
	Events.player_health_changed.emit(current_health, stat_manager.final_max_health)
	Events.player_energy_changed.emit(current_energy, stat_manager.final_energy_max)
	
	# TEMPORARY PHASE 5 INIT: Load test weapon
	var start_weapon = load("res://resources/weapons/weapon_projectile.tres")
	if start_weapon:
		progression.add_weapon(start_weapon)
		progression.unlock_slot(start_weapon.weapon_id, "left_hold") # Give hold for testing
		weapon_handler.weapon_slots[0] = start_weapon
		weapon_handler.set_active_weapon(0)

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_rotation()
	_handle_energy_regen(delta)

func _process(_delta: float) -> void:
	_handle_chrono_switch()

# ----------------------------------------------------------------------
# MOVEMENT & STATS
# ----------------------------------------------------------------------

func _handle_movement() -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * stat_manager.final_speed
	move_and_slide()

func _handle_rotation() -> void:
	var mouse_pos := get_global_mouse_position()
	sprite.rotation = (mouse_pos - global_position).angle() + (PI / 2.0)

func _handle_energy_regen(delta: float) -> void:
	if current_energy < stat_manager.final_energy_max:
		current_energy = minf(stat_manager.final_energy_max, current_energy + (stat_manager.final_energy_regen * delta))
		Events.player_energy_changed.emit(current_energy, stat_manager.final_energy_max)

func _on_stats_changed() -> void:
	if current_health > stat_manager.final_max_health:
		current_health = stat_manager.final_max_health
		Events.player_health_changed.emit(current_health, stat_manager.final_max_health)

# ----------------------------------------------------------------------
# CHRONO-SWITCH SYSTEM
# ----------------------------------------------------------------------

func _handle_chrono_switch() -> void:
	var slot_pressed := -1
	if Input.is_action_just_pressed("weapon_slot_1"): slot_pressed = 0
	elif Input.is_action_just_pressed("weapon_slot_2"): slot_pressed = 1
	elif Input.is_action_just_pressed("weapon_slot_3"): slot_pressed = 2

	if slot_pressed != -1:
		pending_slot_key = slot_pressed
		_animate_time_scale(CHRONO_TIME_SCALE)

	var slot_released := -1
	if Input.is_action_just_released("weapon_slot_1") and pending_slot_key == 0: slot_released = 0
	elif Input.is_action_just_released("weapon_slot_2") and pending_slot_key == 1: slot_released = 1
	elif Input.is_action_just_released("weapon_slot_3") and pending_slot_key == 2: slot_released = 2

	if slot_released != -1:
		print("Committed weapon swap to slot: ", pending_slot_key)
		weapon_handler.set_active_weapon(pending_slot_key) # Phase 5 Stub
		pending_slot_key = -1
		
		# Only return to normal time if no other slot keys are held
		if not (Input.is_action_pressed("weapon_slot_1") or Input.is_action_pressed("weapon_slot_2") or Input.is_action_pressed("weapon_slot_3")):
			_animate_time_scale(1.0)

func _animate_time_scale(target: float) -> void:
	if chrono_tween and chrono_tween.is_running():
		chrono_tween.kill()
	# Time scale manipulation bypasses standard pause rules automatically
	chrono_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	chrono_tween.tween_property(Engine, "time_scale", target, 0.15)

# ----------------------------------------------------------------------
# STATE CHART & COMBAT
# ----------------------------------------------------------------------

func _connect_state_chart() -> void:
	state_chart.get_node("CombatRoot/Neutral").state_entered.connect(_on_neutral_entered)
	state_chart.get_node("CombatRoot/Startup").state_entered.connect(_on_startup_entered)
	state_chart.get_node("CombatRoot/Active").state_entered.connect(_on_active_entered)
	state_chart.get_node("CombatRoot/Recovery/Cooldown").state_entered.connect(_on_cooldown_entered)
	state_chart.get_node("CombatRoot/Recovery/CancelWindow").state_entered.connect(_on_cancel_window_entered)
	state_chart.get_node("CombatRoot/Hitstun").state_entered.connect(_on_hitstun_entered)

func _start_state_timer(duration: float, event_name: String) -> void:
	if _state_timer_tween: _state_timer_tween.kill()
	_state_timer_tween = create_tween()
	_state_timer_tween.tween_callback(func(): state_chart.send_event(event_name)).set_delay(duration)

func _on_neutral_entered() -> void:
	print("[FSM] Neutral")
	can_attack = true
	if _state_timer_tween: _state_timer_tween.kill()

func _on_startup_entered() -> void:
	print("[FSM] Startup")
	can_attack = false
	var delay := active_skill.startup_frames / 60.0 if active_skill else 0.2
	_start_state_timer(delay, "skill_active")

func _on_active_entered() -> void:
	print("[FSM] Active")
	var delay := active_skill.active_frames / 60.0 if active_skill else 0.2
	_start_state_timer(delay, "skill_recovery")

func _on_cooldown_entered() -> void:
	print("[FSM] Cooldown")
	var delay := active_skill.recovery_frames / 60.0 if active_skill else 0.2
	_start_state_timer(delay, "cancel_window_open")

func _on_cancel_window_entered() -> void:
	print("[FSM] Cancel Window")
	Events.cancel_window_open.emit()
	var delay := 0.2 # Fixed tiny window to allow weapon swap cancels
	_start_state_timer(delay, "skill_complete")

func _on_hitstun_entered() -> void:
	print("[FSM] Hitstun")
	can_attack = false
	if _state_timer_tween: _state_timer_tween.kill()
	_start_state_timer(0.5, "hitstun_complete")
