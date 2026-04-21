extends Node

# Stats
signal hp_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal player_died()

# Leveling
signal level_up(new_level: int)

# Key system
signal key_registered(entity: KeyEntity)
signal key_locked(entity: KeyEntity)
signal key_unlocked(entity: KeyEntity)
signal key_press_count_changed(entity: KeyEntity)
signal chain_buffer_changed(buffer: Array)
signal chain_matched(spell: SpellData)

# Wand
signal wand_spell_changed(spell: SpellData)
