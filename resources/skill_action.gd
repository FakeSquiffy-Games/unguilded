class_name SkillAction
extends Resource

@export var skill_id: StringName = &"unnamed_skill"
@export var animation_name: StringName = &"attack"
@export var startup_frames: int = 10
@export var active_frames: int = 10
@export var recovery_frames: int = 20
@export var energy_cost: float = 0.0
@export var cooldown: float = 0.5
@export var base_damage: float = 10.0
@export var knockback_force: float = 0.0
@export var is_energy_drain: bool = false
