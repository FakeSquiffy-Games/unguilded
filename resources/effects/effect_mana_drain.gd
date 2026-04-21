class_name EffectDrainMana
extends KeyEffect

@export var drain_amount: float = 8.0

func on_press(_entity: KeyEntity, player: Player) -> void:
	player.stats.spend_mana(drain_amount)
