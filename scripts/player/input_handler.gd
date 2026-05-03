class_name InputHandler
extends Node
## Differentiates between mouse Taps and Holds for combat skills.

signal left_tap_triggered
signal left_hold_started
signal left_hold_active(delta: float)
signal left_hold_released

signal right_tap_triggered
signal right_hold_started
signal right_hold_active(delta: float)
signal right_hold_released

const HOLD_THRESHOLD: float = 0.175 # 175ms

var _left_timer: float = 0.0
var _left_held: bool = false
var _left_hold_emitted: bool = false

var _right_timer: float = 0.0
var _right_held: bool = false
var _right_hold_emitted: bool = false

func _process(delta: float) -> void:
	_process_click("attack_primary", delta, left_tap_triggered, left_hold_started, left_hold_active, left_hold_released, "_left_timer", "_left_held", "_left_hold_emitted")
	_process_click("attack_secondary", delta, right_tap_triggered, right_hold_started, right_hold_active, right_hold_released, "_right_timer", "_right_held", "_right_hold_emitted")

func _process_click(action: String, delta: float, tap_sig: Signal, hold_start_sig: Signal, hold_active_sig: Signal, hold_release_sig: Signal, timer_var: String, held_var: String, emitted_var: String) -> void:
	if Input.is_action_just_pressed(action):
		set(timer_var, 0.0)
		set(held_var, true)
		set(emitted_var, false)
	
	if Input.is_action_pressed(action) and get(held_var):
		set(timer_var, get(timer_var) + delta)
		if get(timer_var) >= HOLD_THRESHOLD:
			if not get(emitted_var):
				hold_start_sig.emit()
				set(emitted_var, true)
			hold_active_sig.emit(delta)
			
	if Input.is_action_just_released(action):
		set(held_var, false)
		if get(timer_var) < HOLD_THRESHOLD:
			tap_sig.emit()
		elif get(emitted_var):
			hold_release_sig.emit()
