class_name SpellData
extends Resource

enum SpellType { INSTANT, EQUIP_WAND, CHAIN_ONLY }

@export var spell_id: StringName = &"default"
@export var display_name: String = "Basic Shot"
@export var mana_cost: float = 5.0
@export var activation_type: SpellType = SpellType.INSTANT
@export var projectile_scene: PackedScene
@export var damage: float = 10.0
@export var speed: float = 400.0
@export var description: String = ""
