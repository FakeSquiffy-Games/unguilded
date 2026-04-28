class_name EnergyExecutor extends Node
func execute_tap(skill: SkillAction, action_name: String) -> void:
	print("[Energy] Fired Tap: ", action_name)
func execute_hold_active(skill: SkillAction, action_name: String, _delta: float) -> void:
	print("[Energy] Firing Hold Active: ", action_name)
func execute_hold_release(skill: SkillAction, action_name: String) -> void:
	print("[Energy] Fired Hold Release: ", action_name)
