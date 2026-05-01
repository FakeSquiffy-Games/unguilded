class_name SkillCommand
extends Resource
## Base class for all combat skills using the Command Pattern.

@export var skill_id: StringName = &"base_skill"
@export var energy_cost: float = 0.0
@export var cooldown: float = 1.0
@export var base_damage: float = 10.0
@export var knockback_force: float = 0.0

@export_group("FSM Timings (Frames at 60fps)")
@export var startup_frames: int = 5
@export var active_frames: int = 10
@export var recovery_frames: int = 15

# Called on Tap, or when Hold begins
func execute_start(actor: Node2D, target_dir: Vector2) -> void:
	pass

# Called every frame while Holding
func execute_process(actor: Node2D, delta: float) -> void:
	pass

# Called when Hold is released
func execute_release(actor: Node2D) -> void:
	pass
