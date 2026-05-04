class_name HUD
extends Control

# ── Wave / Enemy labels
@onready var wave_label: Label = $Wave
@onready var enemies_left_label: Label = $EnemiesLeft

# ── Health bar
@onready var health_bar: TextureProgressBar = $Health

# ── Character portrait slots
@onready var slot_1: TextureProgressBar = $FirstCharacter
@onready var slot_2: TextureProgressBar = $SecondCharacter
@onready var slot_3: TextureProgressBar = $ThirdCharacter

# ── Cooldown bars — add these four TextureProgressBar nodes to your HUD scene
@onready var cooldown_left_tap: TextureProgressBar = $CooldownLeftTap
@onready var cooldown_left_hold: TextureProgressBar = $CooldownLeftHold
@onready var cooldown_right_tap: TextureProgressBar = $CooldownRightTap
@onready var cooldown_right_hold: TextureProgressBar = $CooldownRightHold

var _player: Actor = null
var _party: PartyManager = null
var _wave_manager: WaveManager = null

# threshold below which a skill is considered unavailable
const UNAVAILABLE_THRESHOLD: float = 10.0
const DIMMED_COLOR: Color = Color(0.25, 0.25, 0.25, 1.0)

func _ready() -> void:
	print(get_parent().name)
	print(get_parent().get_children())
	var portrait_size := Vector2(96, 96)
	for bar in [slot_1, slot_2, slot_3]:
		if bar:
			bar.custom_minimum_size = portrait_size
			bar.size = portrait_size
			bar.scale = Vector2.ONE

	await get_tree().process_frame

	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_party = _player.get_node_or_null("PartyManager")
		health_bar.max_value = _player.max_health

	_wave_manager = get_tree().get_root().find_child("WaveManager", true, false)
	if _wave_manager:
		wave_label.text = "Wave\n%d" % _wave_manager.current_wave
	Events.wave_started.connect(_on_wave_started)

	wave_label.text = "Wave\n0"
	enemies_left_label.text = "Enemy\n0"

func _process(_delta: float) -> void:
	_update_health()
	_update_cooldowns()
	_update_character_portraits()
	_refresh_enemy_count()

# ── Health ────────────────────────────────────────────────────────────────────

func _update_health() -> void:
	if not _player: return
	health_bar.value = _player.current_health

# ── Cooldowns + skill icons ───────────────────────────────────────────────────

func _update_cooldowns() -> void:
	if not _party or _party.roster.is_empty(): return

	var active_char: CharacterNode = _party.get_active()
	if not active_char or not active_char.skill_handler: return

	var handler: SkillHandler = active_char.skill_handler

	_apply_slot(cooldown_left_tap,   handler, "left_tap")
	_apply_slot(cooldown_left_hold,  handler, "left_hold")
	_apply_slot(cooldown_right_tap,  handler, "right_tap")
	_apply_slot(cooldown_right_hold, handler, "right_hold")

func _apply_slot(
	bar: TextureProgressBar,
	handler: SkillHandler,
	slot_key: String
) -> void:
	if not bar: return
	var slot: SkillHandler.SkillSlot = handler.slots.get(slot_key)

	if not slot or not slot.command:
		bar.hide()
		return

	bar.show()

	# set the skill art as the progress fill texture
	if slot.command.get("icon") != null and slot.command.icon:
		bar.texture_progress = slot.command.icon

	# fill based on actual energy
	bar.max_value = slot.max_energy
	bar.value = slot.current_energy

	# dim when unavailable
	var available: bool = slot.current_energy >= UNAVAILABLE_THRESHOLD
	bar.modulate = Color.WHITE if available else DIMMED_COLOR

# ── Character portraits ───────────────────────────────────────────────────────

func _update_character_portraits() -> void:
	if not _party: return
	var portrait_slots := [slot_1, slot_2, slot_3]
	for i in 3:
		var bar: TextureProgressBar = portrait_slots[i]
		if i < _party.roster.size():
			var cnode: CharacterNode = _party.roster[i]
			if cnode.data and cnode.data.get("portrait") != null and cnode.data.portrait:
				bar.texture_under = cnode.data.portrait
			bar.show()
			# highlight active, dim inactive
			bar.modulate = Color.WHITE if i == _party.active_index else DIMMED_COLOR
		else:
			bar.hide()

# ── Wave / Enemy count ────────────────────────────────────────────────w────────

func _on_wave_started(wave: int) -> void:
	wave_label.text = "Wave\n%d" % wave

func _refresh_enemy_count() -> void:
	if not _wave_manager: return
	var alive: int = _wave_manager.active_enemy_count
	var more_coming: bool = _wave_manager.remaining_wave_points > 0
	enemies_left_label.text = "Enemy\n%d%s" % [alive, "+" if more_coming else ""]
