class_name PlayerStats
extends Resource

@export var max_hp: float = 100.0
@export var max_mana: float = 100.0
@export var mana_regen_per_tick: float = 2.0
@export var level: int = 1

var hp: float = max_hp
var mana: float = max_mana

func init() -> void:
	hp = max_hp
	mana = max_mana
	
func spend_mana(amount: float) -> bool:
	if mana < amount:
		return false
	mana = maxf(0.0, mana - amount)
	SignalBus.mana_changed.emit(mana, max_mana)
	return true

func restore_mana(amount: float) -> void:
	mana = minf(max_mana, mana + amount)
	SignalBus.mana_changed.emit(mana, max_mana)

func take_damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)
	SignalBus.hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		SignalBus.player_died.emit()
