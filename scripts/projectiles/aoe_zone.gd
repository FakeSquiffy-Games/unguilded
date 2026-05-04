class_name AOEZone
extends Area2D

var creator: Node2D
var skill_data: SkillCommand
var attacker_stats: StatBlock

var lifetime_timer: float = 0.0
var tick_rate: float = 0.0
var tick_timer: float = 0.0
var clears_projectiles: bool = false

func init_zone(p_creator: Node2D, p_skill: SkillCommand, p_stats: StatBlock, p_layer: int, p_mask: int, p_lifetime: float, p_tick_rate: float, p_clears_proj: bool) -> void:
	creator = p_creator
	skill_data = p_skill
	attacker_stats = p_stats
	
	collision_layer = p_layer
	collision_mask = p_mask
	
	lifetime_timer = p_lifetime
	tick_rate = p_tick_rate
	tick_timer = tick_rate
	clears_projectiles = p_clears_proj
	
	if clears_projectiles and not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if lifetime_timer > 0.0:
		lifetime_timer -= delta
		if lifetime_timer <= 0.0:
			_despawn()
			return

	if tick_rate > 0.0:
		tick_timer -= delta
		if tick_timer <= 0.0:
			tick_timer = tick_rate
			for body in get_overlapping_bodies():
				if body.has_method("take_damage"):
					# Push enemies outward from the center of the zone
					var dir = (body.global_position - global_position).normalized()
					var result = CombatResolver.resolve(attacker_stats, skill_data, null, dir)
					body.take_damage(result)

func _on_area_entered(area: Area2D) -> void:
	if not clears_projectiles: return
	# Projectiles are often CharacterBody2D, but if they use Area2D hitboxes, catch them here.
	if area.is_in_group("enemy_projectiles") and area.has_method("_despawn"):
		area._despawn()

func _despawn() -> void:
	PoolManager.release(self)
