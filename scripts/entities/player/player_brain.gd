class_name PlayerBrain
extends Node

@onready var actor: Actor = get_parent()
@onready var party_manager: PartyManager = $"../PartyManager"

const HOLD_THRESHOLD: float = 0.175
var _left_timer: float = 0.0
var _left_held: bool = false
var _right_timer: float = 0.0
var _right_held: bool = false

var pending_slot_key: int = -1
var chrono_tween: Tween
const CHRONO_TIME_SCALE: float = 0.3

func _ready() -> void:
	await actor.ready
	
	party_manager.character_switched.connect(_on_character_switched)
	actor.death_animation_finished.connect(func(): get_tree().reload_current_scene.call_deferred())
	
	# Load Test Party
	party_manager.add_character(load("res://resources/characters/char_archer.tres"))
	party_manager.add_character(load("res://resources/characters/char_mage.tres"))

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	actor.set_facing(actor.global_position + direction) # Face movement dir by default
	actor.set_facing(actor.get_global_mouse_position()) # Override to face mouse
	
	actor.move(direction, delta)

func _process(delta: float) -> void:
	_handle_chrono_switch()
	_handle_combat_inputs(delta)

func _handle_combat_inputs(delta: float) -> void:
	_process_button("attack_primary", "left", delta)
	_process_button("attack_secondary", "right", delta)

func _process_button(action: String, side: String, delta: float) -> void:
	var timer_var = "_" + side + "_timer"
	var held_var = "_" + side + "_held"
	var dir = (actor.get_global_mouse_position() - actor.global_position).normalized()

	if Input.is_action_just_pressed(action):
		set(timer_var, 0.0)
		set(held_var, true)
	
	if Input.is_action_pressed(action) and get(held_var):
		set(timer_var, get(timer_var) + delta)
		if get(timer_var) >= HOLD_THRESHOLD:
			# Start the Hold skill FSM sequence if not already in it
			if actor.pending_action != side + "_hold":
				actor.request_skill(side + "_hold", dir)
			actor.request_hold_process(side + "_hold", delta)
			
	if Input.is_action_just_released(action):
		set(held_var, false)
		if get(timer_var) < HOLD_THRESHOLD:
			actor.request_skill(side + "_tap", dir)
		else:
			actor.request_hold_release(side + "_hold")

func _handle_chrono_switch() -> void:
	var slot_pressed := -1
	if Input.is_action_just_pressed("character_slot_1"): slot_pressed = 0
	elif Input.is_action_just_pressed("character_slot_2"): slot_pressed = 1
	elif Input.is_action_just_pressed("character_slot_3"): slot_pressed = 2

	if slot_pressed != -1 and slot_pressed < party_manager.roster.size():
		pending_slot_key = slot_pressed
		_animate_time_scale(CHRONO_TIME_SCALE)

	var slot_released := -1
	if Input.is_action_just_released("character_slot_1") and pending_slot_key == 0: slot_released = 0
	elif Input.is_action_just_released("character_slot_2") and pending_slot_key == 1: slot_released = 1
	elif Input.is_action_just_released("character_slot_3") and pending_slot_key == 2: slot_released = 2

	if slot_released != -1:
		party_manager.switch_character(pending_slot_key)
		pending_slot_key = -1
		
		if not (Input.is_action_pressed("character_slot_1") or Input.is_action_pressed("character_slot_2") or Input.is_action_pressed("character_slot_3")):
			_animate_time_scale(1.0)

func _animate_time_scale(target: float) -> void:
	if chrono_tween and chrono_tween.is_running(): chrono_tween.kill()
	chrono_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	chrono_tween.tween_property(Engine, "time_scale", target, 0.15)

func _on_character_switched(cnode: CharacterNode) -> void:
	# Inject the new character's data into the generic Actor puppet!
	actor.sprite.sprite_frames = cnode.data.sprite_frames
	actor.sprite.play("idle")
	
	# The Actor updates its internal stats and skill handler to match the new character
	actor.initialize_stats(cnode.data.base_stats)
	actor.skill_handler = cnode.skill_handler
