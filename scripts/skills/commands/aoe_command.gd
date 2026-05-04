class_name AOECommand
extends SkillCommand

@export var zone_scene: PackedScene
@export var lifetime: float = 3.0
@export var tick_rate: float = 0.5
@export var spawn_at_mouse: bool = true
@export var attach_to_actor: bool = false
@export var clears_enemy_projectiles: bool = false

@export_flags_2d_physics var collision_layer: int = 8
@export_flags_2d_physics var collision_mask: int = 6

func execute_effect(actor: Node2D, _target_dir: Vector2, _slot_data: Dictionary) -> void:
	if not zone_scene: return
	
	var zone = PoolManager.acquire(zone_scene) as AOEZone
	if not zone: return
	
	if attach_to_actor:
		if zone.get_parent(): zone.get_parent().remove_child(zone)
		actor.add_child(zone)
		zone.position = Vector2.ZERO
	else:
		var entities = PoolManager.get_tree().current_scene.find_child("Entities", true, false)
		if entities:
			if zone.get_parent(): zone.get_parent().remove_child(zone)
			entities.add_child(zone)
		
		zone.global_position = actor.get_global_mouse_position() if spawn_at_mouse else actor.global_position
		
	var stats = StatBlock.new()
	if actor.has_node("StatManager"):
		var sm = actor.get_node("StatManager")
		stats.damage_multiplier = sm.final_damage_multiplier
		stats.knockback_resistance = sm.final_knockback_resistance
		
	zone.init_zone(actor, self.duplicate(), stats, collision_layer, collision_mask, lifetime, tick_rate, clears_enemy_projectiles)
