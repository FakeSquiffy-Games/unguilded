@tool
extends EditorScript

func _run() -> void:
	# Build Base Stats
	var archer_stats = StatBlock.new()
	archer_stats.move_speed = 350.0
	var mage_stats = StatBlock.new()
	mage_stats.move_speed = 200.0 # Slower but regenerates energy faster
	mage_stats.energy_regen = 25.0
	
	# Build the Arrow Command
	var arrow_cmd = ProjectileCommand.new()
	arrow_cmd.projectile_scene = load("res://scenes/projectiles/arrow.tscn")
	arrow_cmd.cooldown = 0.4
	
	# Assemble Archer
	var archer = CharacterData.new()
	archer.character_name = "Archer"
	archer.sprite_texture = load("res://icon.svg")
	archer.base_stats = archer_stats
	archer.left_tap = arrow_cmd
	ResourceSaver.save(archer, "res://resources/char_archer.tres")
	
	# Assemble Mage (Uses same command for testing, but different cooldowns)
	var fast_arrow_cmd = ProjectileCommand.new()
	fast_arrow_cmd.projectile_scene = load("res://scenes/projectiles/arrow.tscn")
	fast_arrow_cmd.cooldown = 0.1 # Machine gun arrow
	fast_arrow_cmd.energy_cost = 5.0
	
	var mage = CharacterData.new()
	mage.character_name = "Mage"
	mage.sprite_texture = load("res://icon.svg")
	mage.base_stats = mage_stats
	mage.left_tap = fast_arrow_cmd
	ResourceSaver.save(mage, "res://resources/char_mage.tres")
	
	print("Phase 9: Characters Generated!")
