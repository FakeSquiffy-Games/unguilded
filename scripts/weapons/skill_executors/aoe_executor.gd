class_name AOEExecutor extends Node
func execute_tap(skill: SkillAction, action_name: String) -> void:
	print("[AOE] Fired Tap: ", action_name)
func execute_hold_active(skill: SkillAction, action_name: String, _delta: float) -> void:
	print("[AOE] Firing Hold Active: ", action_name)
func execute_hold_release(skill: SkillAction, action_name: String) -> void:
	print("[AOE] Fired Hold Release: ", action_name)
