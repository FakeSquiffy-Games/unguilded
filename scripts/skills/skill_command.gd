class_name SkillCommand
extends Resource
## Stateless base class for all combat skills using the Command Pattern.

enum SkillType { TAP, HOLD_CONTINUOUS, HOLD_CHARGE }

@export var skill_id: StringName = &"base_skill"
@export var skill_type: SkillType = SkillType.TAP
@export var icon: Texture2D

@export_group("Energy Mechanics")
@export var energy_requirement: float = 100.0 # Cost to fire Tap/Charge, or Drain-Per-Second for Continuous
@export var base_regen: float = 100.0 # How much energy refills per second

@export_group("Combat Stats")
@export var base_damage: float = 10.0
@export var knockback_force: float = 300.0

@export_group("FSM Timings (Frames at 60fps)")
@export var startup_frames: int = 12
@export var active_frames: int = 2
@export var recovery_frames: int = 4

@export_group("Modifiers")
@export var move_speed_multiplier: float = 1.0
@export var grants_iframes: bool = false

# Called on Tap, or when Hold begins
func execute_effect(actor: Node2D, target_dir: Vector2, slot_data: Dictionary) -> void:
	pass

# Called every frame while Holding
func execute_process(actor: Node2D, delta: float, slot_data: Dictionary) -> void:
	pass

# Called when Hold is released
func execute_release(actor: Node2D, slot_data: Dictionary) -> void:
	pass
