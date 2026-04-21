class_name KeyEffect
extends Resource

## Called when the key is pressed (after lock check, before spell)
func on_press(_entity: KeyEntity, _player: Player) -> void:
	pass

## Called when the key is first registered
func on_register(_entity: KeyEntity) -> void:
	pass

## Called when the key entity is removed
func on_remove(_entity: KeyEntity) -> void:
	pass

## Called when press is blocked (key is locked)
func on_blocked(_entity: KeyEntity, _player: Player) -> void:
	pass
