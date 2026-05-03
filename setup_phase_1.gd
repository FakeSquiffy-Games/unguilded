@tool
extends EditorScript

## Run this script from the Script Editor: File -> Run (Ctrl+Shift+X)
func _run() -> void:
	print("--- Starting Phase 1 Scaffold ---")
	
	_create_directories()
	_create_gdlint_config()
	_create_autoload_stubs()
	_configure_project_settings()
	
	print("--- Phase 1 Scaffold Complete! Please restart the Godot Editor. ---")

func _create_directories() -> void:
	var dirs: Array[String] =[
		"autoload",
		"scenes/player", "scenes/enemies", "scenes/projectiles", "scenes/arena", "scenes/ui",
		"scripts/player", "scripts/components", "scripts/enemies", "scripts/weapons/skill_executors", "scripts/systems", "scripts/ui", "scripts/arena",
		"resources/skill_actions", "resources/weapons", "resources/upgrades", "resources/stat_blocks",
		"assets/sprites", "assets/audio", "assets/shaders",
		"tests"
	]
	
	for dir in dirs:
		var path := "res://" + dir
		if not DirAccess.dir_exists_absolute(path):
			DirAccess.make_dir_recursive_absolute(path)
			print("Created directory: ", path)

func _create_gdlint_config() -> void:
	var path := "res://.gdlint.cfg"
	if not FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.WRITE)
		var content := """[limits]
file_lines_soft = 250
file_lines_hard = 400
function_lines = 40
function_lines_critical = 70
max_parameters = 4
max_nesting = 4
cyclomatic_warning = 10
cyclomatic_critical = 15
ascii_only_project_wide = false

[checks]
file_length = true
function_length = true
cyclomatic_complexity = true
parameters = true
nesting = true
todo_comments = true
print_statements = true
empty_functions = true
magic_numbers = true
commented_code = true
missing_types = true
god_class = true
naming_conventions = true
unused_variables = true
unused_parameters = true
ascii_only = true
sealed_classes = true

[exclude]
paths = addons/, tests/
"""
		file.store_string(content)
		print("Created .gdlint.cfg")

func _create_autoload_stubs() -> void:
	var autoloads: Dictionary = {
		"events.gd": """#@ascii_only
extends Node
## Global typed signal bus.

# Player Signals
# signal player_health_changed(current: int, maximum: int)

# Combat Signals
# signal enemy_died(enemy: Node)
""",
		"combat_resolver.gd": """#@ascii_only
extends Node
## Stateless math Autoload for resolving combat outcomes.
""",
		"game_manager.gd": """#@ascii_only
extends Node
## Top-level game orchestration and state management.
""",
		"pool_manager.gd": """#@ascii_only
extends Node
## Object pool registry for projectiles and enemies.
""",
		"audio_manager.gd": """#@ascii_only
extends Node
## Global audio orchestration.
"""
	}
	
	for filename: String in autoloads.keys():
		var path := "res://autoload/" + filename
		if not FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_string(autoloads[filename])
			print("Created autoload stub: ", path)

func _configure_project_settings() -> void:
	# 1. Display Settings
	ProjectSettings.set_setting("display/window/size/viewport_width", 1920)
	ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	
	# 2. Input Map Settings
	_add_key_action("weapon_slot_1", KEY_E)
	_add_key_action("weapon_slot_2", KEY_R)
	_add_key_action("weapon_slot_3", KEY_F)
	_add_mouse_action("attack_primary", MOUSE_BUTTON_LEFT)
	_add_mouse_action("attack_secondary", MOUSE_BUTTON_RIGHT)
	
	# 3. Autoload Registrations
	_add_autoload("Events", "res://autoload/events.gd")
	_add_autoload("CombatResolver", "res://autoload/combat_resolver.gd")
	_add_autoload("GameManager", "res://autoload/game_manager.gd")
	_add_autoload("PoolManager", "res://autoload/pool_manager.gd")
	_add_autoload("AudioManager", "res://autoload/audio_manager.gd")
	
	ProjectSettings.save()
	print("Project Settings Updated (Inputs, Resolution, Autoloads).")

func _add_key_action(action_name: String, keycode: Key) -> void:
	var setting_name := "input/" + action_name
	if not ProjectSettings.has_setting(setting_name):
		var event := InputEventKey.new()
		event.keycode = keycode
		ProjectSettings.set_setting(setting_name, {"deadzone": 0.5, "events": [event]})

func _add_mouse_action(action_name: String, button: MouseButton) -> void:
	var setting_name := "input/" + action_name
	if not ProjectSettings.has_setting(setting_name):
		var event := InputEventMouseButton.new()
		event.button_index = button
		ProjectSettings.set_setting(setting_name, {"deadzone": 0.5, "events": [event]})

func _add_autoload(autoload_name: String, path: String) -> void:
	var setting_name := "autoload/" + autoload_name
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, "*" + path)
