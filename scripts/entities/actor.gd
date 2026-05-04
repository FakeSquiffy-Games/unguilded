class_name Actor
extends CharacterBody2D

signal death_animation_finished

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var stat_manager: StatManager = $StatManager
@onready var skill_handler: SkillHandler = $SkillHandler
@onready var state_chart: StateChart = $StateChart

var current_health: int
var max_health: int

var is_immobilized: bool = false
var can_attack: bool = true

var active_skill: SkillCommand
var pending_action: StringName = &""
var pending_dir: Vector2 = Vector2.ZERO
var _is_action_held: bool = false

var _state_timer_tween: Tween

func _ready() -> void:
	_connect_state_chart()

# ----------------------------------------------------------------------
# PUPPET API (Called by Brains)
# ----------------------------------------------------------------------

func initialize_stats(base_stats: StatBlock) -> void:
	stat_manager.base_stats = base_stats
	stat_manager._recalculate() # Force instant update
	max_health = stat_manager.final_max_health
	current_health = max_health

func move(direction: Vector2, delta: float) -> void:
	if not is_immobilized:
		velocity = direction * stat_manager.final_speed
		if direction.length() > 0:
			state_chart.send_event("movement_started")
		else:
			state_chart.send_event("movement_stopped")
	else:
		# Recoil / Hitstun friction
		velocity = velocity.move_toward(Vector2.ZERO, 1500 * delta)
		state_chart.send_event("movement_stopped")
	
	move_and_slide()

func set_facing(target_pos: Vector2) -> void:
	if is_immobilized: return
	
	var is_neutral = state_chart.get_node("ParallelRoot/CombatRoot/Neutral").active
	if not is_neutral and active_skill:
		# TAP COMMIT RULE
		if active_skill.skill_type == SkillCommand.SkillType.TAP:
			return
			
	sprite.flip_h = target_pos.x < global_position.x

func request_skill(action_name: String, target_dir: Vector2) -> void:
	if not can_attack: return
	
	if skill_handler.validate_and_pay(action_name):
		pending_action = action_name
		pending_dir = target_dir
		active_skill = skill_handler.slots[action_name].command
		_is_action_held = (active_skill.skill_type != SkillCommand.SkillType.TAP)
		
		state_chart.send_event("skill_requested")

func request_hold_process(action_name: String, delta: float) -> void:
	if state_chart.get_node("ParallelRoot/CombatRoot/Active").active and not is_immobilized:
		var success = skill_handler.try_execute_process(action_name, delta)
		if not success:
			# SKILL JAM
			_is_action_held = false
			state_chart.send_event("skill_recovery")

func request_hold_release(action_name: String) -> void:
	skill_handler.try_execute_release(action_name)
	if pending_action == action_name:
		_is_action_held = false
		state_chart.send_event("skill_recovery")

func take_damage(result: CombatResolver.CombatResult) -> void:
	current_health -= int(result.final_damage)
	velocity += result.knockback
	
	if current_health <= 0:
		state_chart.send_event("died")
		collision_shape.set_deferred("disabled", true)
	else:
		state_chart.send_event("took_damage")

# ----------------------------------------------------------------------
# FSM CALLBACKS (Identical to previous Player logic)
# ----------------------------------------------------------------------

func _connect_state_chart() -> void:
	var combat = state_chart.get_node("ParallelRoot/CombatRoot")
	
	combat.get_node("Neutral").state_entered.connect(func(): 
		can_attack = true; is_immobilized = false
		if _state_timer_tween: _state_timer_tween.kill()
	)
	
	combat.get_node("Startup").state_entered.connect(func(): 
		can_attack = false; is_immobilized = false
		_start_scaled_timer((active_skill.startup_frames / 60.0) if active_skill else 0.2, "skill_active")
	)
	
	combat.get_node("Active").state_entered.connect(func(): 
		if pending_action != &"":
			skill_handler.execute_effect(pending_action, pending_dir)
			
		if active_skill and active_skill.skill_type != SkillCommand.SkillType.TAP:
			if not _is_action_held:
				state_chart.send_event("skill_recovery")
			else:
				if _state_timer_tween: _state_timer_tween.kill()
		else:
			_start_scaled_timer((active_skill.active_frames / 60.0) if active_skill else 0.2, "skill_recovery")
	)
	
	combat.get_node("Recovery/Cooldown").state_entered.connect(func(): 
		pending_action = &""
		_start_scaled_timer((active_skill.recovery_frames / 60.0) if active_skill else 0.2, "cancel_window_open")
	)
	
	combat.get_node("Recovery/CancelWindow").state_entered.connect(func(): 
		Events.cancel_window_open.emit()
		_start_scaled_timer(0.2, "skill_complete")
	)
	
	combat.get_node("Hitstun").state_entered.connect(func(): 
		can_attack = false; is_immobilized = true 
		if _state_timer_tween: _state_timer_tween.kill()
		_start_scaled_timer(0.3, "hitstun_complete")
	)
	
	combat.get_node("Death").state_entered.connect(func(): 
		can_attack = false; is_immobilized = true
		if _state_timer_tween: _state_timer_tween.kill()
	)

func _start_scaled_timer(base_duration: float, event_name: String) -> void:
	if _state_timer_tween: _state_timer_tween.kill()
	
	# Defensive check for valid multiplier
	var mult: float = 1.0
	if is_instance_valid(stat_manager):
		mult = stat_manager.final_casting_multiplier
		
	_state_timer_tween = create_tween()
	_state_timer_tween.tween_callback(func(): 
		if is_instance_valid(state_chart):
			state_chart.send_event(event_name)
	).set_delay(base_duration / mult)

# ----------------------------------------------------------------------
# POOLING API
# ----------------------------------------------------------------------

func revive(scaled_stats: StatBlock = null) -> void:
	if scaled_stats:
		initialize_stats(scaled_stats)
	else:
		initialize_stats(stat_manager.base_stats)
		
	is_immobilized = false
	can_attack = true
	collision_shape.set_deferred("disabled", false)
	
	# Force the state chart out of Death and back to Neutral
	state_chart.send_event("revive")
