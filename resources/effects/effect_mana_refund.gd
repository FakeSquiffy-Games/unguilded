class_name EffectRefundMana
extends KeyEffect

@export var every_n: int = 3
@export var mana_refund: float = 15.0

func on_press(entity: KeyEntity, player: Player) -> void:
	if entity.press_count % every_n == 0:
		player.stats.restore_mana(mana_refund)
