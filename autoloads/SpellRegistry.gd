extends Node

@export var all_offers: Array[KeyEntity] = []

func get_random_offers(count: int) -> Array[KeyEntity]:
	var available := all_offers.filter(
		func(e: KeyEntity): return not KeyManager.registered_keys.has(e.key)
	)
	available.shuffle()
	return available.slice(0, mini(count, available.size()))
