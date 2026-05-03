class_name CharacterData
extends Resource

@export var character_name: StringName = &"Unknown"
@export var sprite_frames: SpriteFrames
@export var base_stats: StatBlock

@export_group("Skills")
@export var left_tap: SkillCommand
@export var left_hold: SkillCommand
@export var right_tap: SkillCommand
@export var right_hold: SkillCommand
