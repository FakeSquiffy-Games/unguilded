extends Node

var all_offers: Array[KeyEntity] = []

func _ready() -> void:
	all_offers = [
		load("res://resources/spells/key_a_fireball.tres"),
		load("res://resources/spells/key_k_icelance.tres"),
		load("res://resources/spells/key_j_icelance.tres"),  # same spell, different key
		load("res://resources/spells/key_s_default.tres"),
	]

func get_random_offers(count: int) -> Array[KeyEntity]:
	var available := all_offers.filter(
		func(e: KeyEntity): return not KeyManager.registered_keys.has(e.key)
	)
	available.shuffle()
	return available.slice(0, mini(count, available.size()))
