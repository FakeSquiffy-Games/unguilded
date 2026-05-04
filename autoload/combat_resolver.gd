#@ascii_only
extends Node
## Stateless math Autoload for resolving combat outcomes.

class CombatResult:
	var final_damage: float = 0.0
	var knockback: Vector2 = Vector2.ZERO
	var triggered_hitstun: bool = false
	
	func _init(p_damage: float, p_knockback: Vector2, p_hitstun: bool) -> void:
		final_damage = p_damage
		knockback = p_knockback
		triggered_hitstun = p_hitstun

func resolve(attacker_stats: StatBlock, skill: SkillCommand, defender_stats: StatBlock, attack_direction: Vector2 = Vector2.ZERO) -> CombatResult:
	# Calculate base damage with multipliers
	var damage: float = skill.base_damage * attacker_stats.damage_multiplier
	
	# Future-proofing: Armor/Mitigation math would go here using defender_stats.
	var final_damage: float = maxf(0.0, damage)
	
	# Mitigate force based on defender's resistance
	var resistance: float = defender_stats.knockback_resistance if defender_stats else 0.0
	var actual_force: float = skill.knockback_force * maxf(0.0, 1.0 - resistance)
	var applied_knockback: Vector2 = attack_direction.normalized() * actual_force
	
	# Only trigger hitstun if the resulting force is still strong enough
	var triggers_hitstun: bool = actual_force >= 300.0 
	
	return CombatResult.new(final_damage, applied_knockback, triggers_hitstun)
