class_name EffectLockKey
extends KeyEffect

@export var max_presses: int = 5

func on_press(entity: KeyEntity, _player: Player) -> void:
	if entity.press_count >= max_presses:
		entity.lock()
