class_name Player
extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var state_chart: StateChart = $StateChart
@onready var input_handler: InputHandler = $InputHandler
@onready var party_manager: PartyManager = $PartyManager
@onready var hurtbox: Area2D = $Hurtbox

# Global Party Health
var global_max_health: int = 100
var current_health: int = 100

var can_attack: bool = true
var is_immobilized: bool = false
var active_skill: SkillCommand

# Chrono-Switch
var pending_slot_key: int = -1
var chrono_tween: Tween
const CHRONO_TIME_SCALE: float = 0.3

# FSM Timers
var _state_timer_tween: Tween

func _ready() -> void:
	_connect_state_chart()
	
	party_manager.character_switched.connect(_on_character_switched)
	hurtbox.body_entered.connect(_on_hurtbox_entered)
	
	# Wire Inputs to current character's SkillHandler
	input_handler.left_tap_triggered.connect(func(): _request_skill("left_tap"))
	# (Hold signals would be wired similarly here in the future)

	Events.player_health_changed.emit(current_health, global_max_health)
	
	# TEMP INIT: Load Party
	party_manager.add_character(load("res://resources/characters/char_archer.tres"))
	party_manager.add_character(load("res://resources/characters/char_mage.tres"))

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_rotation()

func _process(_delta: float) -> void:
	_handle_chrono_switch()
	
	# UI Energy updates for active character
	var active = party_manager.get_active()
	if active:
		Events.player_energy_changed.emit(active.current_energy, active.stat_manager.final_energy_max)

# ----------------------------------------------------------------------
# PARTY & COMBAT
# ----------------------------------------------------------------------

func _on_character_switched(cnode: CharacterNode) -> void:
	sprite.texture = cnode.data.sprite_texture
	# In a full game, you might tween scale/color here to make the swap punchy
	print("Switched to: ", cnode.data.character_name)

func _request_skill(action_name: String) -> void:
	if not can_attack: return
	var active_char = party_manager.get_active()
	if not active_char: return
	
	var dir = (get_global_mouse_position() - global_position).normalized()
	
	# Hacky but effective injection of current_energy for the generic SkillHandler to check
	self.set_meta("current_energy", active_char.current_energy) 
	
	active_skill = active_char.skill_handler.try_execute_start(action_name, dir)
	
	if active_skill:
		active_char.current_energy = self.get_meta("current_energy") # Retrieve if drained
		state_chart.send_event("skill_requested")

# ----------------------------------------------------------------------
# PHYSICS & RECOIL
# ----------------------------------------------------------------------

func _handle_movement(delta: float) -> void:
	if not is_immobilized:
		var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var spd = 300.0
		var active = party_manager.get_active()
		if active: spd = active.stat_manager.final_speed
		
		velocity = direction * spd
	else:
		# During Hitstun/Recoil, friction applies
		velocity = velocity.move_toward(Vector2.ZERO, 1500 * delta)
		
	move_and_slide()

func _handle_rotation() -> void:
	if not can_attack: return
	sprite.flip_h = get_global_mouse_position().x < global_position.x

func _on_hurtbox_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		current_health -= 10
		Events.player_health_changed.emit(current_health, global_max_health)
		
		# RECOIL: Bounce away from the enemy
		var bounce_dir := (global_position - body.global_position).normalized()
		velocity = bounce_dir * 800.0 
		
		state_chart.send_event("player_hit") # Triggers FSM Hitstun (disabling movement/attacks)

# ----------------------------------------------------------------------
# CHRONO-SWITCH SYSTEM
# ----------------------------------------------------------------------

func _handle_chrono_switch() -> void:
	var slot_pressed := -1
	if Input.is_action_just_pressed("weapon_slot_1"): slot_pressed = 0
	elif Input.is_action_just_pressed("weapon_slot_2"): slot_pressed = 1
	elif Input.is_action_just_pressed("weapon_slot_3"): slot_pressed = 2

	if slot_pressed != -1 and slot_pressed < party_manager.roster.size():
		pending_slot_key = slot_pressed
		_animate_time_scale(CHRONO_TIME_SCALE)

	var slot_released := -1
	if Input.is_action_just_released("weapon_slot_1") and pending_slot_key == 0: slot_released = 0
	elif Input.is_action_just_released("weapon_slot_2") and pending_slot_key == 1: slot_released = 1
	elif Input.is_action_just_released("weapon_slot_3") and pending_slot_key == 2: slot_released = 2

	if slot_released != -1:
		party_manager.switch_character(pending_slot_key)
		pending_slot_key = -1
		
		if not (Input.is_action_pressed("weapon_slot_1") or Input.is_action_pressed("weapon_slot_2") or Input.is_action_pressed("weapon_slot_3")):
			_animate_time_scale(1.0)

func _animate_time_scale(target: float) -> void:
	if chrono_tween and chrono_tween.is_running(): chrono_tween.kill()
	chrono_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	chrono_tween.tween_property(Engine, "time_scale", target, 0.15)

# ----------------------------------------------------------------------
# FSM CALLBACKS
# ----------------------------------------------------------------------
func _connect_state_chart() -> void:
	state_chart.get_node("CombatRoot/Neutral").state_entered.connect(func(): 
		can_attack = true
		is_immobilized = false # Ensure we can move
		if _state_timer_tween: _state_timer_tween.kill()
	)
	
	state_chart.get_node("CombatRoot/Startup").state_entered.connect(func(): 
		can_attack = false # Block other skills
		is_immobilized = false # CAN still move while winding up
		_start_state_timer((active_skill.startup_frames / 60.0) if active_skill else 0.2, "skill_active")
	)
	
	state_chart.get_node("CombatRoot/Active").state_entered.connect(func(): 
		_start_state_timer((active_skill.active_frames / 60.0) if active_skill else 0.2, "skill_recovery")
	)
	
	state_chart.get_node("CombatRoot/Recovery/Cooldown").state_entered.connect(func(): 
		_start_state_timer((active_skill.recovery_frames / 60.0) if active_skill else 0.2, "cancel_window_open")
	)
	
	state_chart.get_node("CombatRoot/Recovery/CancelWindow").state_entered.connect(func(): 
		Events.cancel_window_open.emit()
		_start_state_timer(0.2, "skill_complete")
	)
	
	state_chart.get_node("CombatRoot/Hitstun").state_entered.connect(func(): 
		can_attack = false 
		is_immobilized = true # CANNOT move while in Hitstun
		if _state_timer_tween: _state_timer_tween.kill()
		_start_state_timer(0.3, "hitstun_complete")
	)

func _start_state_timer(duration: float, event_name: String) -> void:
	if _state_timer_tween: _state_timer_tween.kill()
	_state_timer_tween = create_tween()
	_state_timer_tween.tween_callback(func(): state_chart.send_event(event_name)).set_delay(duration)

# Required by generic SkillCommands checking for current energy via duck-typing
func get_current_energy() -> float:
	return get_meta("current_energy")
func set_current_energy(val: float) -> void:
	set_meta("current_energy", val)
