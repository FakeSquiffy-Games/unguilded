class_name MovementCommand
extends SkillCommand

enum DashDirection { TOWARD_MOUSE, AWAY_FROM_MOUSE, CURRENT_MOVEMENT }

@export_group("Movement Settings")
@export var dash_speed: float = 800.0
@export var direction_type: DashDirection = DashDirection.TOWARD_MOUSE
## If true, the dash will only happen when the button is released (Required for HOLD_CHARGE)
@export var execute_on_release: bool = false

@export_group("Charge Scaling")
## Bonus damage added per second of holding the charge
@export var damage_mult_per_second: float = 0.5
## Maximum bonus damage multiplier from charging
@export var max_charge_mult: float = 3.0

@export_group("Optional Hitbox")
## If assigned, the dash will spawn this hitbox (Dash-Attack)
@export var hitbox_scene: PackedScene
@export var hitbox_offset: float = 0.0

func execute_effect(actor: Node2D, target_dir: Vector2, slot_data: Dictionary) -> void:
	if execute_on_release or skill_type == SkillType.HOLD_CHARGE:
		# Just initialize the charge data, do NOT dash yet
		slot_data["charge_time"] = 0.0
		slot_data["dash_dir"] = target_dir
		return
	
	# If it's a TAP skill, dash immediately
	_perform_dash(actor, target_dir, 1.0)

func execute_process(_actor: Node2D, delta: float, slot_data: Dictionary) -> void:
	if slot_data.has("charge_time"):
		slot_data["charge_time"] += delta

func execute_release(actor: Node2D, slot_data: Dictionary) -> void:
	if not slot_data.has("charge_time"): return
	
	var charge = slot_data.get("charge_time", 0.0)
	var final_mult = 1.0 + minf(charge * damage_mult_per_second, max_charge_mult)
	
	# Update direction to current mouse position for precision
	var dir = (actor.get_global_mouse_position() - actor.global_position).normalized()
	if direction_type == DashDirection.AWAY_FROM_MOUSE: dir = -dir
	
	_perform_dash(actor, dir, final_mult)
	
	# CLEANUP: Crucial to prevent double-firing
	slot_data.erase("charge_time")
	
	# FSM HOOK: Since we are in the 'Active' state of a Hold skill, 
	# we must tell the Actor to finally move to Recovery.
	if actor.has_method("state_chart"): # Safe check
		actor.state_chart.send_event("skill_recovery")

func _perform_dash(actor: Node2D, dir: Vector2, multiplier: float) -> void:
	if not actor is Actor: return
	
	actor.is_dashing = true
	actor.velocity = dir * dash_speed
	
	# If this movement has a hitbox (like Swordsman Pierce), spawn it
	if hitbox_scene:
		_spawn_dash_hitbox(actor, dir, multiplier)

func _spawn_dash_hitbox(actor: Node2D, dir: Vector2, multiplier: float) -> void:
	var hb = PoolManager.acquire(hitbox_scene) as Hitbox
	if not hb: return
	
	# Attach to actor so the hitbox travels with the dash
	if hb.get_parent(): hb.get_parent().remove_child(hb)
	actor.add_child(hb)
	hb.position = dir * hitbox_offset
	hb.rotation = dir.angle()
	
	var stats = StatBlock.new()
	if actor.has_node("StatManager"):
		var sm = actor.get_node("StatManager")
		stats.damage_multiplier = sm.final_damage_multiplier * multiplier
		stats.knockback_resistance = sm.final_knockback_resistance
		
	# Initialize with a lifetime equal to the dash duration (Active + Recovery)
	var duration = (active_frames + recovery_frames) / 60.0
	hb.init_hitbox(actor, self, stats, 8, 6, duration, 0.0)
