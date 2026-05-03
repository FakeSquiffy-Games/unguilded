class_name Player
extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var state_chart: StateChart = $StateChart
@onready var input_handler: InputHandler = $InputHandler
@onready var party_manager: PartyManager = $PartyManager
@onready var hurtbox: Area2D = $Hurtbox

# Global Party Health
var global_max_health: int = 100
var current_health: int = 100

var can_attack: bool = true
var is_immobilized: bool = false
var _is_moving: bool = false
var active_skill: SkillCommand

# Chrono-Switch
var pending_slot_key: int = -1
var pending_action: StringName = &""
var pending_dir: Vector2 = Vector2.ZERO
var _is_action_held: bool = false
var chrono_tween: Tween
const CHRONO_TIME_SCALE: float = 0.3

# FSM Timers
var _state_timer_tween: Tween

func _ready() -> void:
	_connect_state_chart()
	party_manager.character_switched.connect(_on_character_switched)
	hurtbox.body_entered.connect(_on_hurtbox_entered)
	
	input_handler.left_tap_triggered.connect(func(): _request_skill("left_tap"))
	input_handler.right_tap_triggered.connect(func(): _request_skill("right_tap"))
	input_handler.left_hold_started.connect(func(): _request_skill("left_hold"))
	input_handler.right_hold_started.connect(func(): _request_skill("right_hold"))
	
	input_handler.left_hold_active.connect(func(d): _request_hold_process("left_hold", d))
	input_handler.right_hold_active.connect(func(d): _request_hold_process("right_hold", d))
	
	input_handler.left_hold_released.connect(func(): _request_hold_release("left_hold"))
	input_handler.right_hold_released.connect(func(): _request_hold_release("right_hold"))
	
	Events.player_health_changed.emit(current_health, global_max_health)
	
	party_manager.add_character(load("res://resources/characters/char_archer.tres"))
	party_manager.add_character(load("res://resources/characters/char_mage.tres"))

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_rotation()

func _process(_delta: float) -> void:
	_handle_chrono_switch()

# ----------------------------------------------------------------------
# PARTY & COMBAT
# ----------------------------------------------------------------------

func _on_character_switched(cnode: CharacterNode) -> void:
	sprite.sprite_frames = cnode.data.sprite_frames
	sprite.play("idle")
	print("Switched to: ", cnode.data.character_name)

func _request_skill(action_name: String) -> void:
	if not can_attack: return
	var active_char = party_manager.get_active()
	if not active_char: return
	
	if active_char.skill_handler.validate_and_pay(action_name):
		pending_action = action_name
		pending_dir = (get_global_mouse_position() - global_position).normalized()
		active_skill = active_char.skill_handler.slots[action_name].command
		
		# Flag if this is a hold-type skill
		_is_action_held = (active_skill.skill_type != SkillCommand.SkillType.TAP)
		
		state_chart.send_event("skill_requested")

func _request_hold_process(action_name: String, delta: float) -> void:
	# We only process holds if the wind-up is finished and we are Active
	if state_chart.get_node("ParallelRoot/CombatRoot/Active").active:
		var active_char = party_manager.get_active()
		if active_char and not is_immobilized:
			
			var success = active_char.skill_handler.try_execute_process(action_name, delta)
			
			if not success:
				# WEAPON JAM! Tank is empty.
				# Unflag the physical hold and force the FSM into Recovery.
				# Because we leave the Active state, the energy drain STOPS instantly
				# even if the player keeps holding the mouse button down.
				_is_action_held = false
				state_chart.send_event("skill_recovery")

func _request_hold_release(action_name: String) -> void:
	var active_char = party_manager.get_active()
	if active_char:
		active_char.skill_handler.try_execute_release(action_name)
	
	if pending_action == action_name:
		_is_action_held = false
		# We released the button, force the FSM out of Active and into Recovery
		state_chart.send_event("skill_recovery")
# ----------------------------------------------------------------------
# PHYSICS & RECOIL
# ----------------------------------------------------------------------

func _handle_movement(delta: float) -> void:
	var was_moving = _is_moving
	
	if not is_immobilized:
		var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var spd = 300.0
		var active = party_manager.get_active()
		if active: spd = active.stat_manager.final_speed
		
		velocity = direction * spd
		_is_moving = direction.length() > 0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 1500 * delta)
		_is_moving = false
		
	move_and_slide()
	
	# Send events to the Movement State Chart
	if _is_moving and not was_moving:
		state_chart.send_event("movement_started")
	elif not _is_moving and was_moving:
		state_chart.send_event("movement_stopped")

func _handle_rotation() -> void:
	# 1. Hard Lock: Hitstun/Recoil always prevents flipping
	if is_immobilized: return
	
	# 2. Check FSM State: Are we in the middle of a combat action?
	var is_neutral = state_chart.get_node("ParallelRoot/CombatRoot/Neutral").active
	
	if not is_neutral and active_skill:
		# 3. TAP COMMIT RULE: 
		# If it's a Tap skill, lock the flip_h until we return to Neutral.
		# This prevents "Backwards Shooting" bugs.
		if active_skill.skill_type == SkillCommand.SkillType.TAP:
			return
			
	# 4. Fluidity: If Neutral OR performing a Hold skill, allow flipping
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
	state_chart.get_node("ParallelRoot/CombatRoot/Neutral").state_entered.connect(func(): 
		can_attack = true
		is_immobilized = false
		if _state_timer_tween: _state_timer_tween.kill()
	)
	
	state_chart.get_node("ParallelRoot/CombatRoot/Startup").state_entered.connect(func(): 
		can_attack = false
		is_immobilized = false
		_start_scaled_timer((active_skill.startup_frames / 60.0) if active_skill else 0.2, "skill_active")
	)
	
	state_chart.get_node("ParallelRoot/CombatRoot/Active").state_entered.connect(func(): 
		var active_char = party_manager.get_active()
		if active_char and pending_action != &"":
			active_char.skill_handler.execute_effect(pending_action, pending_dir)
			
		# If it's a Hold skill, stay in Active indefinitely!
		if active_skill and active_skill.skill_type != SkillCommand.SkillType.TAP:
			if not _is_action_held:
				# Edge case: The player released the button during the Startup wind-up. 
				# Go to recovery instantly.
				state_chart.send_event("skill_recovery")
			else:
				# Suspend the timer. We wait here until _request_hold_release() happens.
				if _state_timer_tween: _state_timer_tween.kill()
		else:
			# It's a standard Tap skill, use the automatic animation timer
			_start_scaled_timer((active_skill.active_frames / 60.0) if active_skill else 0.2, "skill_recovery")
	)
	
	state_chart.get_node("ParallelRoot/CombatRoot/Recovery/Cooldown").state_entered.connect(func(): 
		pending_action = &"" # Clear pending action
		_start_scaled_timer((active_skill.recovery_frames / 60.0) if active_skill else 0.2, "cancel_window_open")
	)
	
	state_chart.get_node("ParallelRoot/CombatRoot/Recovery/CancelWindow").state_entered.connect(func(): 
		Events.cancel_window_open.emit()
		_start_scaled_timer(0.2, "skill_complete")
	)
	
	state_chart.get_node("ParallelRoot/CombatRoot/Hitstun").state_entered.connect(func(): 
		can_attack = false 
		is_immobilized = true 
		if _state_timer_tween: _state_timer_tween.kill()
		_start_scaled_timer(0.3, "hitstun_complete")
	)

func _start_scaled_timer(base_duration: float, event_name: String) -> void:
	if _state_timer_tween: _state_timer_tween.kill()
	
	var mult: float = 1.0
	var active_char = party_manager.get_active()
	if active_char: mult = active_char.stat_manager.final_casting_multiplier
	
	var final_duration = base_duration / mult
	
	_state_timer_tween = create_tween()
	_state_timer_tween.tween_callback(func(): state_chart.send_event(event_name)).set_delay(final_duration)
