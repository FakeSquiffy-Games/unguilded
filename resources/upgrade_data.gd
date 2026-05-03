class_name UpgradeData
extends Resource

enum UpgradeType { CHAR_STAT, SKILL_SLOT, WEAPON_ACQUISITION }

@export var upgrade_id: StringName = &"unnamed_upgrade"
@export var upgrade_type: UpgradeType = UpgradeType.CHAR_STAT
@export var display_name: String = "Upgrade"
@export_multiline var description: String = ""

@export_group("Stat Modifier")
## Only used if upgrade_type is CHAR_STAT
@export var stat_modifier: StatBlock

@export_group("Unlock Targets")
## Only used if upgrade_type is SKILL_SLOT or WEAPON_ACQUISITION
@export var target_weapon_id: StringName = &""
@export var target_skill_slot: StringName = &""
