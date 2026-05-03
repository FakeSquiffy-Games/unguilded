@tool
extends EditorScript

func _run() -> void:
	# Archer Stats
	var archer_stats = StatBlock.new()
	archer_stats.move_speed = 350.0
	archer_stats.casting_multiplier = 1.0 # Standard Cast Speed
	
	# Mage Stats
	var mage_stats = StatBlock.new()
	mage_stats.move_speed = 200.0
	mage_stats.casting_multiplier = 3.0 # FSM is 3x faster, Regens 3x faster
	
	# Standard Arrow Tap
	var arrow_cmd = ProjectileCommand.new()
	arrow_cmd.skill_type = SkillCommand.SkillType.TAP
	arrow_cmd.projectile_scene = load("res://scenes/projectiles/arrow.tscn")
	arrow_cmd.energy_requirement = 100.0
	arrow_cmd.base_regen = 100.0 # Regens in 1 second
	
	# Machine Gun Hold (Continuous)
	var mg_cmd = ProjectileCommand.new()
	mg_cmd.skill_type = SkillCommand.SkillType.HOLD_CONTINUOUS
	mg_cmd.projectile_scene = load("res://scenes/projectiles/arrow.tscn")
	mg_cmd.energy_requirement = 40.0 # Drains 40/s
	mg_cmd.base_regen = 20.0 # Regens 20/s
	mg_cmd.fire_rate = 0.1
	
	var archer = CharacterData.new()
	archer.character_name = "Archer"
	archer.sprite_texture = load("res://icon.svg")
	archer.base_stats = archer_stats
	archer.left_tap = arrow_cmd
	archer.left_hold = mg_cmd
	ResourceSaver.save(archer, "res://resources/char_archer.tres")
	
	var mage = CharacterData.new()
	mage.character_name = "Mage"
	mage.sprite_texture = load("res://icon.svg")
	mage.base_stats = mage_stats
	mage.left_tap = arrow_cmd
	mage.left_hold = mg_cmd
	ResourceSaver.save(mage, "res://resources/char_mage.tres")
	
	print("Phase 10: Energy System Resources Generated!")
