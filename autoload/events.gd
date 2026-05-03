#@ascii_only
extends Node
## Global typed signal bus.

# Player Signals
signal player_health_changed(current: int, maximum: int)

# Combat Signals
signal enemy_died(enemy: Node)

# Weapon / Input Signals
signal skill_requested
signal cancel_window_open
signal player_hit

# Progression & UI Signals
signal skill_energy_updated(character_name: StringName, slot_name: String, current_energy: float, max_energy: float)
signal weapon_switched(slot_index: int)
signal weapon_acquired(weapon: Resource)
