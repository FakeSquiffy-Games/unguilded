#@ascii_only
extends Node
## Global typed signal bus.

# Player Signals
signal player_health_changed(current: int, maximum: int)
signal player_energy_changed(current: float, maximum: float)

# Combat Signals
signal enemy_died(enemy: Node)

# Weapon / Input Signals
signal skill_requested
signal cancel_window_open
signal player_hit

# Progression & UI Signals
signal cooldown_updated(slot_index: int, action_name: StringName, remaining: float, total: float)
signal weapon_switched(slot_index: int)
signal weapon_acquired(weapon: WeaponResource)
