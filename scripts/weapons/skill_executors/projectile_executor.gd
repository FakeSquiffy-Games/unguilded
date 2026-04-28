class_name ProjectileExecutor
extends Node

const POOL_NAME: StringName = &"weapon_projectile_pool"
var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")

var _hold_fire_timer: float = 0.0
var _charge_timer: float = 0.0

@onready var player: Player = owner

func _ready() -> void:
	PoolManager.register_pool(POOL_NAME, projectile_scene, 30)

func execute_tap(skill: SkillAction, action_name: String) -> void:
	if action_name == "left_tap":
		# Standard fast shot
		_fire_projectile(skill, 800.0, false, 1.0)
	elif action_name == "right_tap":
		# Laser Tap: Extremely fast, elongated sprite, piercing
		_fire_projectile(skill, 4000.0, true, 1.0, 1.0, true)

func execute_hold_active(skill: SkillAction, action_name: String, delta: float) -> void:
	if action_name == "left_hold":
		_hold_fire_timer -= delta
		if _hold_fire_timer <= 0.0:
			_fire_projectile(skill, 800.0, false, 0.7)
			_hold_fire_timer = 0.12 # Fire rate
	elif action_name == "right_hold":
		_charge_timer += delta

func execute_hold_release(skill: SkillAction, action_name: String) -> void:
	if action_name == "right_hold":
		# Charged Laser Burst: Max 3x damage, thicker beam, ultra fast
		var multiplier: float = 1.0 + minf(_charge_timer * 1.5, 3.0) 
		_fire_projectile(skill, 5000.0, true, multiplier, multiplier, true)
		_charge_timer = 0.0

func _fire_projectile(skill: SkillAction, speed: float, piercing: bool, dmg_mult: float, scale_mult: float = 1.0, is_laser: bool = false) -> void:
	var proj := PoolManager.acquire(POOL_NAME) as ProjectileBase
	if not proj: return
	
	var pos := player.global_position
	var dir := (player.get_global_mouse_position() - pos).normalized()
	var stats := player.stat_manager.base_stats
	
	var applied_skill := skill.duplicate() as SkillAction
	applied_skill.base_damage *= dmg_mult
	
	proj.init_projectile(POOL_NAME, pos, dir, speed, piercing, applied_skill, stats)
	
	if is_laser:
		# Stretch Y to make it a long line, shrink X to make it thin (Godot sprites face Y- up by default)
		proj.scale = Vector2(0.04 * scale_mult, 1.5 * scale_mult)
		# Optional: Modulate color to red for lasers so they stand out
		proj.modulate = Color(1.0, 0.2, 0.2, 1.0) 
	else:
		proj.scale = Vector2.ONE * scale_mult * 0.2
		proj.modulate = Color.WHITE
		
	proj.add_collision_exception_with(player)
