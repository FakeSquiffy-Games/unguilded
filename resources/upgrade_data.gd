class_name UpgradeData
extends Resource

enum UpgradeType { SLOT_UPGRADE, CHAR_STAT, CHAR_UNLOCK }

@export var upgrade_id: StringName = &"unnamed_upgrade"
@export var upgrade_type: UpgradeType = UpgradeType.CHAR_STAT
@export var display_name: String = "Upgrade"
@export_multiline var description: String = ""

@export_group("Payload Data")
## Used if SLOT_UPGRADE (e.g., "left_tap", "left_hold")
@export var target_slot: String = "" 

## Used if CHAR_STAT
@export var stat_modifier: StatBlock

## Used if CHAR_UNLOCK
@export var character_data: CharacterData
