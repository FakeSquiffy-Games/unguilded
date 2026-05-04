class_name MeleeCommand
extends SkillCommand

@export var hitbox_scene: PackedScene
@export var hitbox_offset: float = 40.0
@export var hitbox_lifetime: float = 0.2

@export_group("Continuous Mechanics")
## If > 0, the hitbox remains active and clears its hit-list every X seconds (e.g., Flamethrower)
@export var tick_rate: float = 0.0
## If ticking, should the hitbox snap to the player's position?
@export var attach_to_actor: bool = true
## If tick_rate is 0.0 but the skill is HOLD_CONTINUOUS, how fast do rapid slashes spawn?
@export var rapid_slash_rate: float = 0.3 

@export_group("Physics")
@export_flags_2d_physics var collision_layer: int = 8
@export_flags_2d_physics var collision_mask: int = 6

func execute_effect(actor: Node2D, target_dir: Vector2, slot_data: Dictionary) -> void:
	if skill_type == SkillType.TAP:
		_spawn_hitbox(actor, target_dir)
		
	elif skill_type == SkillType.HOLD_CONTINUOUS:
		if tick_rate > 0.0:
			# FLAMETHROWER MODE: Spawn one lingering hitbox and store it
			var hb = _spawn_hitbox(actor, target_dir, true)
			slot_data["active_hitbox"] = hb
		else:
			# TRIPLE SLASH COMBO MODE: Spawn the first slash, start the timer
			_spawn_hitbox(actor, target_dir)
			slot_data["fire_timer"] = rapid_slash_rate

func execute_process(actor: Node2D, delta: float, slot_data: Dictionary) -> void:
	if skill_type != SkillType.HOLD_CONTINUOUS: return
	
	var dir = (actor.get_global_mouse_position() - actor.global_position).normalized()
	
	if tick_rate > 0.0:
		# FLAMETHROWER MODE: Update rotation and keep the deadman switch alive
		var hb = slot_data.get("active_hitbox")
		if is_instance_valid(hb):
			hb.feed_deadman_switch()
			hb.rotation = dir.angle()
			if attach_to_actor:
				hb.position = dir * hitbox_offset
	else:
		# TRIPLE SLASH COMBO MODE: Spawn a new slash when the timer fires
		var timer = slot_data.get("fire_timer", 0.0)
		timer -= delta 
		if timer <= 0.0:
			_spawn_hitbox(actor, dir)
			timer = rapid_slash_rate
		slot_data["fire_timer"] = timer

func execute_release(_actor: Node2D, slot_data: Dictionary) -> void:
	# If we release the Flamethrower, we can manually kill it early for responsiveness
	if tick_rate > 0.0:
		var hb = slot_data.get("active_hitbox")
		if is_instance_valid(hb):
			hb._despawn()
		slot_data.erase("active_hitbox")

func _spawn_hitbox(actor: Node2D, dir: Vector2, force_continuous: bool = false) -> Hitbox:
	if not hitbox_scene: return null
	var hb = PoolManager.acquire(hitbox_scene) as Hitbox
	if not hb: return null
	
	var should_attach = (force_continuous and attach_to_actor)
	
	if should_attach:
		if hb.get_parent(): hb.get_parent().remove_child(hb)
		actor.add_child(hb)
		hb.position = dir * hitbox_offset
	else:
		var entities = PoolManager.get_tree().current_scene.find_child("Entities", true, false)
		if entities:
			if hb.get_parent(): hb.get_parent().remove_child(hb)
			entities.add_child(hb)
		hb.global_position = actor.global_position + (dir * hitbox_offset)
	
	hb.rotation = dir.angle()
	
	var stats = StatBlock.new()
	if actor.has_node("StatManager"):
		var sm = actor.get_node("StatManager")
		stats.damage_multiplier = sm.final_damage_multiplier
		stats.knockback_resistance = sm.final_knockback_resistance
		
	var applied_cmd = self.duplicate() as SkillCommand
	var pass_lifetime = 0.0 if force_continuous else hitbox_lifetime
	
	hb.init_hitbox(actor, applied_cmd, stats, collision_layer, collision_mask, pass_lifetime, tick_rate)
	return hb
