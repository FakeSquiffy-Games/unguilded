class_name Player
extends CharacterBody2D

@export var stats: PlayerStats
@export var move_speed: float = 200.0
@export var arrival_threshold: float = 4.0

@onready var wand: Wand = $Wand
@onready var mana_timer: Timer = $ManaTimer

var move_target: Vector2 = Vector2.ZERO
var _moving: bool = false

func _ready() -> void:
	if stats == null:
		stats = PlayerStats.new()
	SignalBus.hp_changed.emit(stats.hp, stats.max_hp)
	SignalBus.mana_changed.emit(stats.mana, stats.max_mana)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			move_target = get_global_mouse_position()
			_moving = true
		elif event.button_index == MOUSE_BUTTON_LEFT:
			wand.try_fire(get_global_mouse_position())

#func _unhandled_key_input(event: InputEventKey) -> void:
	#if event.pressed and not event.is_echo():
		#KeyManager.handle_key(event.keycode, self)

func _physics_process(_delta: float) -> void:
	if not _moving:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var diff := move_target - global_position
	if diff.length() <= arrival_threshold:
		_moving = false
		velocity = Vector2.ZERO
	else:
		velocity = diff.normalized() * move_speed
	move_and_slide()

func _on_mana_timer_timeout() -> void:
	stats.restore_mana(stats.mana_regen_per_tick)

func level_up() -> void:
	stats.level += 1
	SignalBus.level_up.emit(stats.level)
