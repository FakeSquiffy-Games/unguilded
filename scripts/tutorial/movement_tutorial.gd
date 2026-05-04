extends Node2D

const FADE_DELAY: float = 5.0
const FADE_DURATION: float = 1.5
const PRESSED_MODULATE: float = 0.4
const HOVER_OFFSET: Vector2 = Vector2(-5, -60)

@onready var key_w: Sprite2D = $MovementGroup/TopRow/KeyW
@onready var key_a: Sprite2D = $MovementGroup/BottomRow/KeyA
@onready var key_s: Sprite2D = $MovementGroup/BottomRow/KeyS
@onready var key_d: Sprite2D = $MovementGroup/BottomRow/KeyD
@onready var wasd_group: Control = $MovementGroup

var _fade_timer: float = FADE_DELAY
var _has_faded: bool = false
var _tween: Tween

func _ready() -> void:
	position = HOVER_OFFSET
	modulate.a = 1.0
	print(key_w, key_a, key_s, key_d)

func _process(delta: float) -> void:
	if _has_faded:
		return
	_update_key_visuals()
	_fade_timer -= delta
	if _fade_timer <= 0.0:
		_start_fade()

func _update_key_visuals() -> void:
	_set_key_pressed(key_w, Input.is_action_pressed("ui_up"))
	_set_key_pressed(key_a, Input.is_action_pressed("ui_left"))
	_set_key_pressed(key_s, Input.is_action_pressed("ui_down"))
	_set_key_pressed(key_d, Input.is_action_pressed("ui_right"))

func _set_key_pressed(key: Sprite2D, pressed: bool) -> void:
	key.modulate = Color(PRESSED_MODULATE, PRESSED_MODULATE, PRESSED_MODULATE) if pressed else Color.WHITE

func _start_fade() -> void:
	_has_faded = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	_tween.tween_callback(queue_free)
