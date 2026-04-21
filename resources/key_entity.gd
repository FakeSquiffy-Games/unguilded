class_name KeyEntity
extends Resource

@export var key: Key = KEY_NONE
@export var display_label: String = ""
@export var spell: SpellData
@export var effects: Array[KeyEffect] = []

var press_count: int = 0
var is_locked: bool = false

func increment_press() -> void:
	press_count += 1
	SignalBus.key_press_count_changed.emit(self)

func lock() -> void:
	is_locked = true
	SignalBus.key_locked.emit(self)

func unlock() -> void:
	is_locked = false
	SignalBus.key_unlocked.emit(self)
