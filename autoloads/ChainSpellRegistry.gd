extends Node

var _registry: Dictionary = {}

func register_chain(sequence: Array, spell: SpellData) -> void:
	var key := _seq_to_key(sequence)
	_registry[key] = spell

func match_sequence(buffer: Array) -> SpellData:
	var key := _seq_to_key(buffer)
	return _registry.get(key, null)

func has_prefix(buffer: Array) -> bool:
	var prefix := _seq_to_key(buffer)
	for k in _registry:
		if k.begins_with(prefix):
			return true
	return false

func _seq_to_key(seq: Array) -> String:
	return "|".join(seq.map(func(k): return str(k)))
