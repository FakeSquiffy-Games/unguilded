extends Node2D

func _ready() -> void:
	# Register chain sequences → spell combos
	# Format: register_chain([KEY_A, KEY_B, ...], spell_resource)
	
	var fireball: SpellData = load("res://resources/spells/fireball.tres")
	ChainSpellRegistry.register_chain([KEY_A, KEY_K, KEY_J], fireball)
	
	var ice_lance: SpellData = load("res://resources/spells/ice_lance.tres")
	ChainSpellRegistry.register_chain([KEY_S, KEY_S], ice_lance)
