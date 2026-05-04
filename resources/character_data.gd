class_name CharacterData
extends Resource

@export var character_name: StringName = &"Unknown"
@export var sprite_frames: SpriteFrames
@export var base_stats: StatBlock

@export_group("Skill Tiers (Level 1, Level 2, etc.)")
@export var left_tap_tiers: Array[SkillCommand] = []
@export var left_hold_tiers: Array[SkillCommand] =[]
@export var right_tap_tiers: Array[SkillCommand] =[]
@export var right_hold_tiers: Array[SkillCommand] =[]
