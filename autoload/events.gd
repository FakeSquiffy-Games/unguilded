#@ascii_only
extends Node
## Global typed signal bus.

# Control Signals
signal stats_changed
signal skill_requested
signal cancel_window_open

# Gameplay Signals
signal skill_energy_updated(character_name: StringName, slot_name: String, current_energy: float, max_energy: float)
signal character_acquired(character: CharacterData)
signal enemy_died(enemy: Node)

# Wave Signals
signal wave_started(wave_num: int)
signal wave_cleared(wave_num: int)
