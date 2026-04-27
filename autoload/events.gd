#@ascii_only
extends Node
## Global typed signal bus.

# Player Signals
signal player_health_changed(current: int, maximum: int)
signal player_energy_changed(current: float, maximum: float)

# Combat Signals
signal enemy_died(enemy: Node)
