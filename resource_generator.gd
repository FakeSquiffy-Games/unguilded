@tool
extends EditorScript

func _run() -> void:
	# Create left tap skill
	var tap = SkillAction.new()
	tap.skill_id = "proj_tap"
	tap.startup_frames = 5
	tap.active_frames = 10
	tap.recovery_frames = 15
	tap.cooldown = 0.4
	tap.energy_cost = 5.0
	ResourceSaver.save(tap, "res://resources/skill_actions/proj_left_tap.tres")
	
	# Create left hold skill
	var hold = SkillAction.new()
	hold.skill_id = "proj_hold"
	hold.is_energy_drain = true
	hold.energy_cost = 30.0 # Drain per second
	ResourceSaver.save(hold, "res://resources/skill_actions/proj_left_hold.tres")
	
	# Create Weapon Resource
	var weapon = WeaponResource.new()
	weapon.weapon_id = "weapon_projectile"
	weapon.left_tap = tap
	weapon.left_hold = hold
	ResourceSaver.save(weapon, "res://resources/weapons/weapon_projectile.tres")
	
	print("Phase 5 Test Resources Created!")
