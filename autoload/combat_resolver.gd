#@ascii_only
extends Node
## Stateless math Autoload for resolving combat outcomes.

## Plain data class to hold the results of a combat calculation
class CombatResult:
	var final_damage: float = 0.0
	var knockback: Vector2 = Vector2.ZERO
	var triggered_hitstun: bool = false
	
	func _init(p_damage: float, p_knockback: Vector2, p_hitstun: bool) -> void:
		final_damage = p_damage
		knockback = p_knockback
		triggered_hitstun = p_hitstun

## Stubbed resolve function for now. Will be fleshed out in Phase 3.
func resolve(attacker_stats: StatBlock, skill: SkillAction, defender_stats: StatBlock) -> CombatResult:
	# Placeholder logic
	var damage := skill.base_damage * attacker_stats.damage_multiplier
	return CombatResult.new(damage, Vector2.ZERO, false)
