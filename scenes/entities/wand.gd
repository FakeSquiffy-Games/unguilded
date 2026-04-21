class_name Wand
extends Node2D

@export var default_spell: SpellData
@onready var fire_point: Marker2D = $FirePoint

var equipped_spell: SpellData = null
var stats: PlayerStats

func _ready() -> void:
	stats = get_parent().stats

func try_fire(target_pos: Vector2) -> void:
	var spell := equipped_spell if equipped_spell else default_spell
	if spell == null:
		return
	if not stats.spend_mana(spell.mana_cost):
		return
	var dir := (target_pos - fire_point.global_position).normalized()
	var p: Projectile = spell.projectile_scene.instantiate()
	p.direction = dir
	p.speed = spell.speed
	p.damage = spell.damage
	p.global_position = fire_point.global_position
	get_tree().root.add_child(p)

func equip_spell(spell: SpellData) -> void:
	equipped_spell = spell
	SignalBus.wand_spell_changed.emit(spell)

func clear_spell() -> void:
	equipped_spell = null
	SignalBus.wand_spell_changed.emit(null)


func _on_mana_timer_timeout() -> void:
	pass # Replace with function body.

func fire_raw(target_pos: Vector2) -> void:
	var spell := equipped_spell if equipped_spell else default_spell
	if spell == null or spell.projectile_scene == null:
		return
	var dir := (target_pos - fire_point.global_position).normalized()
	var p: Projectile = spell.projectile_scene.instantiate()
	p.direction = dir
	p.speed = spell.speed
	p.damage = spell.damage
	p.global_position = fire_point.global_position
	get_tree().root.add_child(p)
