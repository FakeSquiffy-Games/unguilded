@tool
extends EditorScript

func _run() -> void:
	var tap = SkillAction.new()
	tap.skill_id = "proj_tap"
	tap.startup_frames = 5
	tap.active_frames = 10
	tap.recovery_frames = 15
	tap.cooldown = 0.4
	tap.energy_cost = 5.0
	tap.base_damage = 15.0
	ResourceSaver.save(tap, "res://resources/skill_actions/proj_left_tap.tres")
	
	var hold = SkillAction.new()
	hold.skill_id = "proj_hold"
	hold.is_energy_drain = true
	hold.energy_cost = 20.0
	hold.base_damage = 10.0
	ResourceSaver.save(hold, "res://resources/skill_actions/proj_left_hold.tres")
	
	var r_tap = SkillAction.new()
	r_tap.skill_id = "proj_r_tap"
	r_tap.startup_frames = 8
	r_tap.active_frames = 10
	r_tap.recovery_frames = 20
	r_tap.cooldown = 1.5
	r_tap.energy_cost = 15.0
	r_tap.base_damage = 25.0
	ResourceSaver.save(r_tap, "res://resources/skill_actions/proj_right_tap.tres")
	
	var r_hold = SkillAction.new()
	r_hold.skill_id = "proj_r_hold"
	r_hold.startup_frames = 0
	r_hold.active_frames = 10
	r_hold.recovery_frames = 30
	r_hold.cooldown = 2.0
	r_hold.energy_cost = 40.0 # High cost upfront
	r_hold.base_damage = 50.0 # Base for the charge multiplier
	ResourceSaver.save(r_hold, "res://resources/skill_actions/proj_right_hold.tres")
	
	var weapon = WeaponResource.new()
	weapon.weapon_id = "weapon_projectile"
	weapon.left_tap = tap
	weapon.left_hold = hold
	weapon.right_tap = r_tap
	weapon.right_hold = r_hold
	ResourceSaver.save(weapon, "res://resources/weapons/weapon_projectile.tres")
	
	print("Phase 6 Projectile Resources Fully Generated!")
